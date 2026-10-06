import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/chat_search.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../teams/domain/team_membership.dart';

Future<void> showHomeChatPanel(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeChatPanel(),
    );

class HomeChatPanel extends StatefulWidget {
  const HomeChatPanel({super.key});

  @override
  State<HomeChatPanel> createState() => _HomeChatPanelState();
}

class _HomeChatPanelState extends State<HomeChatPanel>
    with WidgetsBindingObserver {
  final _repository = ChatRepository();
  final _messageController = TextEditingController();
  late Future<List<List<Map<String, dynamic>>>> _overviewFuture;
  Map<String, dynamic>? _selectedPerson;
  String _selectedConversationType = 'direct';
  String? _conversationId;
  String? _lastMarkedMessageId;
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _teamMembershipSubscription;
  Timer? _inboxReloadDebounce;
  bool _notificationWarningShown = false;
  bool _closingRevokedTeamChat = false;
  bool _openingConversation = false;
  bool _sending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _overviewFuture = _loadOverview();
    _listenToInboxChanges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _listenToInboxChanges();
    if (_selectedPerson == null) {
      _reloadOverview();
    } else {
      _reconnectConversation();
    }
  }

  Future<List<List<Map<String, dynamic>>>> _loadOverview() =>
      Future.wait([_repository.fetchInbox(), _repository.fetchPeople()]);

  void _listenToInboxChanges() {
    unawaited(_notificationSubscription?.cancel());
    _notificationSubscription = NotificationRepository().watchMine().listen((
      _,
    ) {
      _notificationWarningShown = false;
      if (_selectedPerson != null || !mounted) return;
      _inboxReloadDebounce?.cancel();
      _inboxReloadDebounce = Timer(const Duration(milliseconds: 180), () {
        if (mounted && _selectedPerson == null) {
          _reloadOverview();
        }
      });
    }, onError: _handleInboxRealtimeError);
  }

  void _handleInboxRealtimeError(Object _) {
    if (!mounted || _notificationWarningShown) return;
    _notificationWarningShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cập nhật hộp thư bị gián đoạn. Hãy bấm làm mới để kết nối lại.',
        ),
      ),
    );
  }

  void _refreshInbox() {
    _notificationWarningShown = false;
    _listenToInboxChanges();
    _reloadOverview();
  }

  void _reloadOverview() {
    final nextOverview = _loadOverview();
    setState(() {
      _overviewFuture = nextOverview;
    });
  }

  void _reconnectConversation() {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    setState(() {
      _lastMarkedMessageId = null;
      _messagesStream = _repository.watchMessages(conversationId);
    });
    final teamId = _selectedPerson?['team_id'] as String?;
    if (_selectedConversationType == 'team' && teamId != null) {
      _listenToSelectedTeamMembership(teamId);
    }
    unawaited(_markReadInBackground(conversationId));
  }

  void _listenToSelectedTeamMembership(String teamId) {
    unawaited(_teamMembershipSubscription?.cancel());
    final userId = _repository.currentUserId;
    if (userId == null) return;
    _closingRevokedTeamChat = false;
    _teamMembershipSubscription = Supabase.instance.client
        .from('team_members')
        .stream(primaryKey: ['team_id', 'user_id'])
        .eq('team_id', teamId)
        .eq('user_id', userId)
        .listen((rows) {
          if (!mounted || _closingRevokedTeamChat) return;
          if (hasJoinedTeamMembership(rows)) return;
          _closingRevokedTeamChat = true;
          _backToInbox();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không còn là thành viên của đội.'),
            ),
          );
        }, onError: _handleSelectedTeamMembershipError);
  }

  void _handleSelectedTeamMembershipError(Object _) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Không thể theo dõi quyền chat đội. Hãy bấm kết nối lại.',
        ),
      ),
    );
  }

  void _backToInbox() {
    unawaited(_teamMembershipSubscription?.cancel());
    _teamMembershipSubscription = null;
    final nextOverview = _loadOverview();
    setState(() {
      _selectedPerson = null;
      _selectedConversationType = 'direct';
      _conversationId = null;
      _lastMarkedMessageId = null;
      _messagesStream = null;
      _overviewFuture = nextOverview;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxReloadDebounce?.cancel();
    unawaited(_notificationSubscription?.cancel());
    unawaited(_teamMembershipSubscription?.cancel());
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final height = (screenSize.height - 24).clamp(280.0, 680.0).toDouble();
    final width = (screenSize.width - 24).clamp(280.0, 430.0).toDouble();
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x88000000), blurRadius: 35),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedPerson == null ? _buildPeople() : _buildConversation(),
      ),
    );
  }

  Widget _buildPeople() => Column(
    children: [
      _ChatHeader(
        title: 'Tin nhắn',
        subtitle: 'Chọn một người để bắt đầu trò chuyện',
        onRefresh: _refreshInbox,
        onClose: () => Navigator.pop(context),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Tìm bạn bè...',
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<List<Map<String, dynamic>>>>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Không thể tải người dùng: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _refreshInbox,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final groups = snapshot.data;
            final inbox = (groups?[0] ?? const <Map<String, dynamic>>[])
                .where((row) => chatSearchMatches(row, _searchQuery))
                .toList();
            final people = (groups?[1] ?? const <Map<String, dynamic>>[])
                .where((row) => chatSearchMatches(row, _searchQuery))
                .toList();
            final recentDirectUserIds = inbox
                .where((row) => row['conversation_type'] != 'team')
                .map((row) => row['other_user_id'])
                .whereType<String>()
                .toSet();
            final otherPeople = people
                .where((person) => !recentDirectUserIds.contains(person['id']))
                .toList();
            if (inbox.isEmpty && people.isEmpty) {
              return Center(
                child: Text(
                  _searchQuery.trim().isEmpty
                      ? 'Chưa có người dùng khác.'
                      : 'Không tìm thấy người hoặc cuộc trò chuyện phù hợp.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                if (inbox.isNotEmpty) ...[
                  const _ChatSectionLabel('GẦN ĐÂY'),
                  for (final conversation in inbox)
                    _chatPersonTile(
                      {
                        'id': conversation['other_user_id'],
                        'display_name': conversation['display_name'],
                        'username': conversation['username'],
                        'avatar_url': conversation['avatar_url'],
                        'team_id': conversation['team_id'],
                      },
                      subtitle:
                          conversation['last_message'] as String? ??
                          (conversation['conversation_type'] == 'team'
                              ? 'Chat đội'
                              : 'Chưa có tin nhắn'),
                      conversationId: conversation['conversation_id'] as String,
                      conversationType:
                          conversation['conversation_type'] as String? ??
                          'direct',
                      unreadCount:
                          (conversation['unread_count'] as num?)?.toInt() ?? 0,
                    ),
                  const Divider(height: 22),
                ],
                if (otherPeople.isNotEmpty) ...[
                  const _ChatSectionLabel('MỌI NGƯỜI'),
                  for (final person in otherPeople) _chatPersonTile(person),
                ],
              ],
            );
          },
        ),
      ),
    ],
  );

  Widget _chatPersonTile(
    Map<String, dynamic> person, {
    String? subtitle,
    String? conversationId,
    String conversationType = 'direct',
    int unreadCount = 0,
  }) {
    final name = (person['display_name'] as String?)?.trim();
    final shownName = name?.isNotEmpty == true ? name! : 'Người dùng';
    final username = (person['username'] as String?)?.trim();
    return ListTile(
      onTap: _openingConversation
          ? null
          : () => _openConversation(
              person,
              existingConversationId: conversationId,
              conversationType: conversationType,
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: AppColors.cyan.withValues(alpha: .14),
        child: Text(
          shownName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.cyan,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        shownName,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle ??
            (username?.isNotEmpty == true
                ? '@$username'
                : (person['city'] as String? ?? 'QuestReal')),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.muted),
      ),
      trailing: unreadCount > 0
          ? Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : const Icon(Icons.chevron_right_rounded),
    );
  }

  Widget _buildConversation() => Column(
    children: [
      _ChatHeader(
        title: (_selectedPerson?['display_name'] as String?) ?? 'Trò chuyện',
        subtitle: _selectedConversationType == 'team'
            ? 'Trò chuyện cùng đội'
            : 'Tin nhắn trực tiếp',
        onRefresh: _reconnectConversation,
        onBack: _backToInbox,
        onClose: () => Navigator.pop(context),
      ),
      Expanded(
        child: _messagesStream == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Không thể tải tin nhắn: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _reconnectConversation,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Kết nối lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final messages =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  if (messages.isNotEmpty) {
                    final latestId = messages.last['id'] as String?;
                    if (latestId != null && latestId != _lastMarkedMessageId) {
                      _lastMarkedMessageId = latestId;
                      final conversationId = _conversationId;
                      if (conversationId != null) {
                        unawaited(_markReadInBackground(conversationId));
                      }
                    }
                  }
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Hãy gửi lời chào đầu tiên.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return ListView.separated(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final mine =
                          message['sender_id'] == _repository.currentUserId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _MessageBubble(
                          text: message['content'] as String? ?? '',
                          mine: mine,
                          senderName:
                              !mine && _selectedConversationType == 'team'
                              ? message['sender_display_name'] as String?
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLength: ChatRepository.maxMessageLength,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  isDense: true,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 7),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _openConversation(
    Map<String, dynamic> person, {
    String? existingConversationId,
    String conversationType = 'direct',
  }) async {
    unawaited(_teamMembershipSubscription?.cancel());
    _teamMembershipSubscription = null;
    setState(() {
      _openingConversation = true;
      _selectedPerson = person;
      _selectedConversationType = conversationType;
    });
    final teamId = person['team_id'] as String?;
    if (conversationType == 'team' && teamId != null) {
      _listenToSelectedTeamMembership(teamId);
    }
    try {
      final conversationId =
          existingConversationId ??
          await _repository.openDirectConversation(person['id'] as String);
      if (!mounted) return;
      setState(() {
        _conversationId = conversationId;
        _messagesStream = _repository.watchMessages(conversationId);
        _openingConversation = false;
      });
      unawaited(_markReadInBackground(conversationId));
    } catch (error) {
      if (!mounted) return;
      unawaited(_teamMembershipSubscription?.cancel());
      _teamMembershipSubscription = null;
      setState(() {
        _openingConversation = false;
        _selectedPerson = null;
        _selectedConversationType = 'direct';
        _conversationId = null;
        _messagesStream = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở trò chuyện: $error')),
      );
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    final conversationId = _conversationId;
    if (message.isEmpty || conversationId == null || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();
    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        content: message,
      );
    } catch (error) {
      if (!mounted) return;
      _messageController.text = message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markReadInBackground(String conversationId) async {
    try {
      await _repository.markRead(conversationId);
    } catch (_) {
      // Best effort
    }
  }
}

class _ChatSectionLabel extends StatelessWidget {
  const _ChatSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.cyan,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.onBack,
    this.onRefresh,
  });
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        if (onBack != null)
          IconButton(
            tooltip: 'Quay lại',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.chat_bubble_rounded, color: AppColors.orange),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Làm mới',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.mine,
    this.senderName,
  });
  final String text;
  final bool mine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final shownSender = senderName?.trim();
    return Container(
      constraints: const BoxConstraints(maxWidth: 285),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.orange : const Color(0xFF2A2D3D),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(15),
          topRight: const Radius.circular(15),
          bottomLeft: Radius.circular(mine ? 15 : 4),
          bottomRight: Radius.circular(mine ? 4 : 15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (shownSender?.isNotEmpty == true) ...[
            Text(
              shownSender!,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
          ],
          Text(text, style: const TextStyle(color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }
}

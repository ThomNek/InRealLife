import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../teams/domain/team_membership.dart';
import '../data/chat_repository.dart';

class TeamChatPage extends StatefulWidget {
  const TeamChatPage({
    super.key,
    this.repository,
    this.teamId,
    this.membershipStream,
  });

  final ChatRepository? repository;
  final String? teamId;
  final Stream<List<Map<String, dynamic>>>? membershipStream;

  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage>
    with WidgetsBindingObserver {
  late final ChatRepository _repository;
  final _messageController = TextEditingController();
  String? _teamId;
  Future<String>? _conversationFuture;
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  StreamSubscription<List<Map<String, dynamic>>>? _membershipSubscription;
  bool _sending = false;
  bool _closingForRevokedAccess = false;
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ChatRepository();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final teamId =
        widget.teamId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (teamId != null && teamId != _teamId) {
      _teamId = teamId;
      _conversationFuture = _repository.openTeamConversation(teamId);
      _messagesStream = null;
      _listenToMembership(teamId);
    }
  }

  void _listenToMembership(String teamId) {
    unawaited(_membershipSubscription?.cancel());
    final userId = _repository.currentUserId;
    if (userId == null) return;

    final stream =
        widget.membershipStream ??
        Supabase.instance.client
            .from('team_members')
            .stream(primaryKey: ['team_id', 'user_id'])
            .eq('team_id', teamId)
            .eq('user_id', userId);
    _membershipSubscription = stream.listen(
      _handleMembership,
      onError: _handleMembershipError,
    );
  }

  void _handleMembership(List<Map<String, dynamic>> rows) {
    if (!mounted || _closingForRevokedAccess) return;
    final joined = hasJoinedTeamMembership(rows);
    if (joined) return;

    _closingForRevokedAccess = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không còn là thành viên của đội.')),
      );
      Navigator.of(context).maybePop();
    });
  }

  void _handleMembershipError(Object _) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể theo dõi quyền chat. Hãy bấm kết nối lại.'),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_membershipSubscription?.cancel());
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _teamId != null) {
      _reconnect();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Chat đội',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: 'Kết nối lại',
          onPressed: _teamId == null ? null : _reconnect,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _conversationFuture == null
        ? const Center(child: Text('Không xác định được đội.'))
        : FutureBuilder<String>(
            future: _conversationFuture,
            builder: (context, conversationSnapshot) {
              if (conversationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (conversationSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Không thể mở chat đội: ${conversationSnapshot.error}',
                    ),
                  ),
                );
              }
              final conversationId = conversationSnapshot.data!;
              _messagesStream ??= _repository.watchMessages(conversationId);
              return Column(
                children: [
                  Expanded(child: _messages(conversationId)),
                  _composer(conversationId),
                ],
              );
            },
          ),
  );

  Widget _messages(
    String conversationId,
  ) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: _messagesStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Không thể tải tin nhắn: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _reconnect,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kết nối lại'),
                ),
              ],
            ),
          ),
        );
      }
      final messages = snapshot.data ?? const <Map<String, dynamic>>[];
      if (messages.isNotEmpty) {
        final latestId = messages.last['id'] as String?;
        if (latestId != null && latestId != _lastMarkedMessageId) {
          _lastMarkedMessageId = latestId;
          unawaited(_markReadInBackground(conversationId));
        }
      }
      if (messages.isEmpty) {
        return const Center(
          child: Text(
            'Chưa có tin nhắn. Hãy thống nhất kế hoạch gặp mặt!',
            style: TextStyle(color: AppColors.muted),
          ),
        );
      }
      return ListView.separated(
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          final mine = message['sender_id'] == _repository.currentUserId;
          return Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.orange : AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: mine ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: mine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!mine) ...[
                    Text(
                      message['sender_display_name'] as String? ?? 'Thành viên',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(message['content'] as String? ?? ''),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Widget _composer(String conversationId) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLength: ChatRepository.maxMessageLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(conversationId),
              decoration: const InputDecoration(
                hintText: 'Nhắn cho cả đội...',
                isDense: true,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : () => _send(conversationId),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );

  Future<void> _send(String conversationId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _messageController.clear();
    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        content: text,
      );
    } catch (error) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _reconnect() {
    final teamId = _teamId;
    if (teamId == null) return;
    setState(() {
      _lastMarkedMessageId = null;
      _messagesStream = null;
      _conversationFuture = _repository.openTeamConversation(teamId);
    });
    _listenToMembership(teamId);
  }

  Future<void> _markReadInBackground(String conversationId) async {
    try {
      await _repository.markRead(conversationId);
    } catch (_) {
      // Thành viên có thể vừa rời/bị kích khỏi đội giữa hai sự kiện Realtime.
      // Không để thao tác đánh dấu nền sinh lỗi bất đồng bộ không được xử lý.
    }
  }
}

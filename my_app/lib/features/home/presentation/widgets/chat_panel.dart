import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/chat_search.dart';
import '../../../friends/data/friend_repository.dart';
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

class ChatOverviewData {
  const ChatOverviewData({
    required this.inbox,
    required this.friends,
    required this.pendingRequests,
    required this.friendshipStatus,
    required this.people,
  });

  final List<Map<String, dynamic>> inbox;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> pendingRequests;
  final Map<String, String> friendshipStatus;
  final List<Map<String, dynamic>> people;
}

class HomeChatPanel extends StatefulWidget {
  const HomeChatPanel({
    super.key,
    this.isStandalonePage = false,
    this.chatRepository,
    this.friendRepository,
  });

  final bool isStandalonePage;
  final ChatRepository? chatRepository;
  final FriendRepository? friendRepository;

  @override
  State<HomeChatPanel> createState() => _HomeChatPanelState();
}

class _HomeChatPanelState extends State<HomeChatPanel>
    with WidgetsBindingObserver {
  late final ChatRepository _repository;
  late final FriendRepository _friendRepository;
  final _messageController = TextEditingController();
  late Future<ChatOverviewData> _overviewFuture;
  Map<String, dynamic>? _selectedPerson;
  String _selectedConversationType = 'direct';
  String? _conversationId;
  String? _lastMarkedMessageId;
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _teamMembershipSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _friendshipSubscription;
  Timer? _inboxReloadDebounce;
  bool _notificationWarningShown = false;
  bool _closingRevokedTeamChat = false;
  bool _openingConversation = false;
  bool _sending = false;
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Hộp thư, 1: Bạn bè, 2: Lời mời, 3: Khám phá
  Map<String, String> _friendshipStatus = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.chatRepository ?? ChatRepository();
    _friendRepository = widget.friendRepository ?? FriendRepository();
    _overviewFuture = _loadOverview();
    _listenToInboxChanges();
    _listenToFriendshipChanges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _listenToInboxChanges();
    _listenToFriendshipChanges();
    if (_selectedPerson == null) {
      _reloadOverview();
    } else {
      _reconnectConversation();
    }
  }

  Future<ChatOverviewData> _loadOverview() async {
    final results = await Future.wait([
      _repository.fetchInbox().catchError((_) => <Map<String, dynamic>>[]),
      _friendRepository.fetchFriends().catchError((_) => <Map<String, dynamic>>[]),
      _friendRepository.fetchPendingReceivedRequests().catchError((_) => <Map<String, dynamic>>[]),
      _friendRepository.fetchFriendshipStatusMap().catchError((_) => <String, String>{}),
      _repository.fetchPeople().catchError((_) => <Map<String, dynamic>>[]),
    ]);

    final statusMap = (results[3] as Map<String, String>?) ?? <String, String>{};
    if (mounted) {
      setState(() {
        _friendshipStatus = statusMap;
      });
    } else {
      _friendshipStatus = statusMap;
    }

    return ChatOverviewData(
      inbox: (results[0] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[],
      friends: (results[1] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[],
      pendingRequests: (results[2] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[],
      friendshipStatus: statusMap,
      people: (results[4] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[],
    );
  }

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

  void _listenToFriendshipChanges() {
    unawaited(_friendshipSubscription?.cancel());
    _friendshipSubscription = _friendRepository.watchFriendships().listen((_) {
      if (mounted) {
        _reloadOverview();
      }
    }, onError: (_) {});
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
    _listenToFriendshipChanges();
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

  Future<void> _sendFriendRequest(String targetUserId) async {
    try {
      await _friendRepository.sendFriendRequest(targetUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lời mời kết bạn!')),
      );
      _reloadOverview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi lời mời kết bạn: $e')),
      );
    }
  }

  Future<void> _acceptFriendRequest(String requesterId) async {
    try {
      await _friendRepository.acceptFriendRequest(requesterId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã trở thành bạn bè!')),
      );
      _reloadOverview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chấp nhận lời mời: $e')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String otherUserId) async {
    try {
      await _friendRepository.removeOrRejectFriend(otherUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối lời mời kết bạn.')),
      );
      _reloadOverview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thao tác không thành công: $e')),
      );
    }
  }

  Future<void> _unfriend(String friendId, String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Bạn có chắc muốn hủy kết bạn với $friendName không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Hủy kết bạn'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _friendRepository.removeOrRejectFriend(friendId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy kết bạn với $friendName.')),
      );
      _reloadOverview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hủy kết bạn: $e')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxReloadDebounce?.cancel();
    unawaited(_notificationSubscription?.cancel());
    unawaited(_friendshipSubscription?.cancel());
    unawaited(_teamMembershipSubscription?.cancel());
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalonePage) {
      return Scaffold(
        body: SafeArea(
          child:
              _selectedPerson == null ? _buildPeople() : _buildConversation(),
        ),
      );
    }

    final screenSize = MediaQuery.sizeOf(context);
    final height = (screenSize.height - 24).clamp(280.0, 720.0).toDouble();
    final width = (screenSize.width - 24).clamp(280.0, 460.0).toDouble();
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
        title: 'Tin nhắn & Bạn bè',
        subtitle: _selectedTab == 0
            ? 'Trò chuyện gần đây'
            : _selectedTab == 1
                ? 'Danh sách bạn bè'
                : _selectedTab == 2
                    ? 'Lời mời kết bạn'
                    : 'Khám phá cộng đồng',
        onRefresh: _refreshInbox,
        onClose: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/');
          }
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: _selectedTab == 0
                ? 'Tìm cuộc trò chuyện...'
                : _selectedTab == 1
                    ? 'Tìm bạn bè...'
                    : _selectedTab == 2
                        ? 'Tìm lời mời...'
                        : 'Tìm người dùng...',
            isDense: true,
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<ChatOverviewData>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
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
                        'Không thể tải dữ liệu: ${snapshot.error}',
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
            final data = snapshot.data ??
                const ChatOverviewData(
                  inbox: [],
                  friends: [],
                  pendingRequests: [],
                  friendshipStatus: {},
                  people: [],
                );
            final pendingCount = data.pendingRequests.length;
            final friendsCount = data.friends.length;

            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'Hộp thư',
                        icon: Icons.chat_bubble_outline_rounded,
                        selected: _selectedTab == 0,
                        onSelected: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: friendsCount > 0
                            ? 'Bạn bè ($friendsCount)'
                            : 'Bạn bè',
                        icon: Icons.people_outline_rounded,
                        selected: _selectedTab == 1,
                        onSelected: () => setState(() => _selectedTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Lời mời',
                        icon: Icons.person_add_alt_1_rounded,
                        badgeCount: pendingCount,
                        selected: _selectedTab == 2,
                        onSelected: () => setState(() => _selectedTab = 2),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Khám phá',
                        icon: Icons.explore_outlined,
                        selected: _selectedTab == 3,
                        onSelected: () => setState(() => _selectedTab = 3),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 12),
                Expanded(
                  child: () {
                    switch (_selectedTab) {
                      case 1:
                        return _buildFriendsTab(data);
                      case 2:
                        return _buildRequestsTab(data);
                      case 3:
                        return _buildExploreTab(data);
                      case 0:
                      default:
                        return _buildInboxTab(data);
                    }
                  }(),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );

  Widget _buildInboxTab(ChatOverviewData data) {
    final inbox = data.inbox
        .where((row) => chatSearchMatches(row, _searchQuery))
        .toList();
    if (inbox.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 44, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                _searchQuery.trim().isEmpty
                    ? 'Chưa có cuộc trò chuyện nào.'
                    : 'Không tìm thấy cuộc trò chuyện phù hợp.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedTab = 3),
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Khám phá người dùng'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      children: [
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
                conversation['conversation_type'] as String? ?? 'direct',
            unreadCount:
                (conversation['unread_count'] as num?)?.toInt() ?? 0,
          ),
      ],
    );
  }

  Widget _buildFriendsTab(ChatOverviewData data) {
    final friends = data.friends
        .where((row) => chatSearchMatches(row, _searchQuery))
        .toList();
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 44, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                _searchQuery.trim().isEmpty
                    ? 'Bạn chưa có bạn bè nào.'
                    : 'Không tìm thấy bạn bè phù hợp.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => setState(() => _selectedTab = 3),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Tìm bạn ngay'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: friends.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final friend = friends[index];
        final name = (friend['display_name'] as String?)?.trim() ?? 'Bạn bè';
        final username = (friend['username'] as String?)?.trim();
        final friendId = friend['id'] as String;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.cyan.withValues(alpha: .15),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            username?.isNotEmpty == true
                ? '@$username'
                : (friend['city'] as String? ?? 'Bạn bè'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Nhắn tin',
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.cyan),
                onPressed: () => _openConversation(friend),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.muted),
                onSelected: (val) {
                  if (val == 'unfriend') {
                    _unfriend(friendId, name);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'unfriend',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Hủy kết bạn',
                            style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _openConversation(friend),
        );
      },
    );
  }

  Widget _buildRequestsTab(ChatOverviewData data) {
    final requests = data.pendingRequests
        .where((row) => chatSearchMatches(row, _searchQuery))
        .toList();
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  size: 44, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                _searchQuery.trim().isEmpty
                    ? 'Không có lời mời kết bạn nào đang chờ.'
                    : 'Không tìm thấy lời mời phù hợp.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final req = requests[index];
        final name = (req['display_name'] as String?)?.trim() ?? 'Người dùng';
        final username = (req['username'] as String?)?.trim();
        final reqId = req['id'] as String;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.orange.withValues(alpha: .15),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            username?.isNotEmpty == true
                ? '@$username'
                : 'Đã gửi lời mời kết bạn',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => _acceptFriendRequest(reqId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Đồng ý',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Từ chối',
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                onPressed: () => _rejectFriendRequest(reqId),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreTab(ChatOverviewData data) {
    final currentUserId = _repository.currentUserId;
    final people = data.people
        .where((person) =>
            person['id'] != currentUserId &&
            chatSearchMatches(person, _searchQuery))
        .toList();
    if (people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _searchQuery.trim().isEmpty
                ? 'Chưa có người dùng khác trong khu vực.'
                : 'Không tìm thấy người dùng phù hợp.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: people.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final person = people[index];
        final personId = person['id'] as String;
        final name = (person['display_name'] as String?)?.trim() ?? 'Người dùng';
        final username = (person['username'] as String?)?.trim();
        final status = data.friendshipStatus[personId];

        return ListTile(
          onTap: () => _openConversation(person),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.cyan.withValues(alpha: .15),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            username?.isNotEmpty == true
                ? '@$username'
                : (person['city'] as String? ?? 'QuestReal'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          trailing: _buildExploreStatusButton(personId, status, name),
        );
      },
    );
  }

  Widget _buildExploreStatusButton(
      String personId, String? status, String name) {
    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withValues(alpha: .3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: AppColors.cyan),
            SizedBox(width: 4),
            Text(
              'Bạn bè',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cyan,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    if (status == 'sent') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.muted),
            SizedBox(width: 4),
            Text(
              'Đã gửi lời mời',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (status == 'received') {
      return FilledButton(
        onPressed: () => _acceptFriendRequest(personId),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.black,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: const Text('Chấp nhận',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: () => _sendFriendRequest(personId),
      icon: const Icon(Icons.person_add_rounded, size: 15),
      label: const Text('Kết bạn', style: TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
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

  Widget _buildConversation() {
    final otherPersonId = _selectedPerson?['id'] as String?;
    final friendshipStatus =
        otherPersonId != null ? _friendshipStatus[otherPersonId] : null;
    final isDirectChat = _selectedConversationType == 'direct';

    return Column(
      children: [
        _ChatHeader(
          title: (_selectedPerson?['display_name'] as String?) ?? 'Trò chuyện',
          subtitle: _selectedConversationType == 'team'
              ? 'Trò chuyện cùng đội'
              : 'Tin nhắn trực tiếp',
          onRefresh: _reconnectConversation,
          onBack: _backToInbox,
          onClose: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        if (isDirectChat &&
            otherPersonId != null &&
            friendshipStatus != 'accepted')
          _buildConversationFriendshipBanner(otherPersonId, friendshipStatus),
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
                      if (latestId != null &&
                          latestId != _lastMarkedMessageId) {
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
  }

  Widget _buildConversationFriendshipBanner(
      String targetUserId, String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: .1),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 18, color: AppColors.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status == 'sent'
                  ? 'Đã gửi lời mời kết bạn'
                  : status == 'received'
                      ? 'Người này đã gửi lời mời kết bạn'
                      : 'Chưa kết bạn',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          if (status == 'sent')
            TextButton(
              onPressed: () => _rejectFriendRequest(targetUserId),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Hủy lời mời',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            )
          else if (status == 'received')
            FilledButton(
              onPressed: () => _acceptFriendRequest(targetUserId),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('Chấp nhận',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => _sendFriendRequest(targetUserId),
              icon: const Icon(Icons.person_add_rounded, size: 14),
              label: const Text('Kết bạn', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      ),
    );
  }

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
      final targetUserId = person['id'] as String?;
      if (existingConversationId == null &&
          (targetUserId == null || targetUserId.isEmpty)) {
        throw ArgumentError(
          'Thiếu thông tin người dùng để mở cuộc trò chuyện.',
        );
      }
      final conversationId =
          existingConversationId ??
          await _repository.openDirectConversation(targetUserId!);
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

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onSelected,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.orange.withValues(alpha: .2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.orange : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? AppColors.orange : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
          if (badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
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
        letterSpacing: 1.1,
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

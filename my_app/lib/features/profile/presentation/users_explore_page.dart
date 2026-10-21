import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_navigation_shell.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../friends/data/friend_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

class UsersExplorePage extends StatefulWidget {
  const UsersExplorePage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<UsersExplorePage> createState() => _UsersExplorePageState();
}

class _UsersExplorePageState extends State<UsersExplorePage> {
  final _profileRepository = ProfileRepository();
  final _friendRepository = FriendRepository();
  final _searchController = TextEditingController();

  List<UserProfile> _users = [];
  Map<String, String> _friendshipStatus = {};
  bool _isLoading = true;
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _profileRepository.searchUsersModel(query: _searchController.text),
        _friendRepository.fetchFriendshipStatusMap(),
      ]);

      if (!mounted) return;
      setState(() {
        _users = results[0] as List<UserProfile>;
        _friendshipStatus = results[1] as Map<String, String>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFriendAction(UserProfile user, String? status) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để kết bạn.')),
      );
      return;
    }

    try {
      if (status == null) {
        // Chưa có lời mời -> Gửi lời mời
        await _friendRepository.sendFriendRequest(user.id);
        if (!mounted) return;
        setState(() {
          _friendshipStatus[user.id] = 'sent';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi lời mời kết bạn tới ${user.displayName}')),
        );
      } else if (status == 'received') {
        // Nhận được lời mời -> Chấp nhận
        await _friendRepository.acceptFriendRequest(user.id);
        if (!mounted) return;
        setState(() {
          _friendshipStatus[user.id] = 'accepted';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã trở thành bạn bè với ${user.displayName}!')),
        );
      } else if (status == 'sent') {
        // Đã gửi -> Hủy lời mời
        await _friendRepository.removeOrRejectFriend(user.id);
        if (!mounted) return;
        setState(() {
          _friendshipStatus.remove(user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy lời mời kết bạn.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thao tác không thành công: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return MainShell(
      selectedIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text(
            'Khám phá bạn bè',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 768;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 24 : 16,
                          14,
                          wide ? 24 : 16,
                          8,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          autofocus: widget.initialQuery.isNotEmpty,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadData();
                                    },
                                  )
                                : null,
                            hintText: 'Tìm theo tên, username, địa chỉ...',
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildBody(currentUserId, wide),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String? currentUserId, bool wide) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.orange),
              const SizedBox(height: 12),
              Text('Lỗi tải danh sách: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded, size: 56, color: AppColors.muted),
              const SizedBox(height: 12),
              const Text(
                'Không tìm thấy người dùng phù hợp',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isEmpty
                    ? 'Hiện tại chưa có người dùng nào khác trong hệ thống.'
                    : 'Thử tìm kiếm với từ khóa khác.',
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        wide ? 24 : 16,
        8,
        wide ? 24 : 16,
        32,
      ),
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isMe = user.id == currentUserId;
        final status = _friendshipStatus[user.id];

        return _UserListItem(
          user: user,
          isMe: isMe,
          friendshipStatus: status,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: user.id,
            );
          },
          onFriendAction: () => _handleFriendAction(user, status),
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  const _UserListItem({
    required this.user,
    required this.isMe,
    required this.friendshipStatus,
    required this.onTap,
    required this.onFriendAction,
  });

  final UserProfile user;
  final bool isMe;
  final String? friendshipStatus;
  final VoidCallback onTap;
  final VoidCallback onFriendAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              UserAvatar(
                radius: 24,
                avatarUrl: user.avatarUrl,
                gender: user.gender,
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BẠN',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (user.username != null && user.username!.isNotEmpty) ...[
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('·', style: TextStyle(color: AppColors.muted)),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'Cấp ${user.level}',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (user.city.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Text('·', style: TextStyle(color: AppColors.muted)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              user.city,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!isMe) _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (friendshipStatus) {
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 14, color: Colors.greenAccent),
              SizedBox(width: 4),
              Text(
                'Bạn bè',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      case 'sent':
        return OutlinedButton(
          onPressed: onFriendAction,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text('Hủy lời mời', style: TextStyle(fontSize: 11)),
        );
      case 'received':
        return FilledButton(
          onPressed: onFriendAction,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: AppColors.cyan,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text('Chấp nhận', style: TextStyle(fontSize: 11)),
        );
      default:
        return FilledButton.tonalIcon(
          onPressed: onFriendAction,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 14),
          label: const Text('Kết bạn', style: TextStyle(fontSize: 11)),
        );
    }
  }
}

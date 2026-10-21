import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/friend_model.dart';

class FriendRepository {
  FriendRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Lấy danh sách bạn bè đã chấp nhận (dạng Model)
  Future<List<FriendItem>> fetchFriendsList() async {
    final rows = await fetchFriends();
    return rows.map((e) => FriendItem.fromMap(e)).toList();
  }

  /// Lấy danh sách lời mời chờ duyệt (dạng Model)
  Future<List<FriendRequestItem>> fetchPendingRequestsList() async {
    final rows = await fetchPendingReceivedRequests();
    return rows.map((e) => FriendRequestItem.fromMap(e)).toList();
  }

  /// Lấy danh sách bạn bè đã chấp nhận
  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final client = _client;
    if (client == null) return [];
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final rows = await client
          .from('friendships')
          .select('''
            user_id,
            friend_id,
            status,
            profiles!friend_id(id, display_name, username, avatar_url, city)
          ''')
          .eq('user_id', user.id)
          .eq('status', 'accepted')
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'id': profile['id'] ?? row['friend_id'],
          'display_name': profile['display_name'] ?? 'Bạn bè',
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'city': profile['city'] ?? '',
          'status': 'accepted',
        };
      }).toList();
    } catch (_) {
      try {
        // Fallback: truy vấn 2 chiều và lấy profile tương ứng
        final friendRows = await client
            .from('friendships')
            .select('user_id, friend_id, status')
            .or('user_id.eq.${user.id},friend_id.eq.${user.id}')
            .eq('status', 'accepted');

        final otherIds = <String>{};
        for (final r in List<Map<String, dynamic>>.from(friendRows)) {
          final uId = r['user_id'] as String;
          final fId = r['friend_id'] as String;
          otherIds.add(uId == user.id ? fId : uId);
        }
        if (otherIds.isEmpty) return [];

        final profiles = await client
            .from('profiles')
            .select('id, display_name, username, avatar_url, city')
            .inFilter('id', otherIds.toList());

        return List<Map<String, dynamic>>.from(profiles).map((p) => {
          'id': p['id'],
          'display_name': p['display_name'] ?? 'Bạn bè',
          'username': p['username'],
          'avatar_url': p['avatar_url'],
          'city': p['city'] ?? '',
          'status': 'accepted',
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Lấy danh sách lời mời kết bạn nhận được đang chờ duyệt
  Future<List<Map<String, dynamic>>> fetchPendingReceivedRequests() async {
    final client = _client;
    if (client == null) return [];
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final rows = await client
          .from('friendships')
          .select('''
            user_id,
            friend_id,
            status,
            created_at,
            profiles!user_id(id, display_name, username, avatar_url, city)
          ''')
          .eq('friend_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'id': profile['id'] ?? row['user_id'],
          'display_name': profile['display_name'] ?? 'Người dùng',
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'city': profile['city'] ?? '',
          'created_at': row['created_at'],
        };
      }).toList();
    } catch (_) {
      try {
        final reqRows = await client
            .from('friendships')
            .select('user_id, friend_id, status, created_at')
            .eq('friend_id', user.id)
            .eq('status', 'pending');

        final senderIds = List<Map<String, dynamic>>.from(reqRows)
            .map((r) => r['user_id'] as String)
            .toList();
        if (senderIds.isEmpty) return [];

        final profiles = await client
            .from('profiles')
            .select('id, display_name, username, avatar_url, city')
            .inFilter('id', senderIds);

        final profileMap = {
          for (final p in List<Map<String, dynamic>>.from(profiles))
            p['id'] as String: p
        };

        return List<Map<String, dynamic>>.from(reqRows).map((r) {
          final uId = r['user_id'] as String;
          final p = profileMap[uId] ?? {};
          return {
            'id': uId,
            'display_name': p['display_name'] ?? 'Người dùng',
            'username': p['username'],
            'avatar_url': p['avatar_url'],
            'city': p['city'] ?? '',
            'created_at': r['created_at'],
          };
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Tra cứu danh sách ID người dùng đã gửi lời mời hoặc là bạn bè
  Future<Map<String, String>> fetchFriendshipStatusMap() async {
    final client = _client;
    if (client == null) return {};
    final user = client.auth.currentUser;
    if (user == null) return {};

    try {
      final rows = await client
          .from('friendships')
          .select('user_id, friend_id, status')
          .or('user_id.eq.${user.id},friend_id.eq.${user.id}');

      final map = <String, String>{};
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final uId = row['user_id'] as String;
        final fId = row['friend_id'] as String;
        final status = row['status'] as String;

        if (uId == user.id) {
          map[fId] = status == 'pending' ? 'sent' : status;
        } else {
          map[uId] = status == 'pending' ? 'received' : status;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Gửi lời mời kết bạn
  Future<void> sendFriendRequest(String targetUserId) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    try {
      await client.rpc(
        'send_friend_request',
        params: {'p_target_user_id': targetUserId},
      );
    } catch (_) {
      // Fallback chèn trực tiếp qua RLS
      await client.from('friendships').upsert({
        'user_id': user.id,
        'friend_id': targetUserId,
        'status': 'pending',
      });
    }
  }

  /// Đồng ý lời mời kết bạn
  Future<void> acceptFriendRequest(String requesterId) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    try {
      await client.rpc(
        'accept_friend_request',
        params: {'p_requester_id': requesterId},
      );
    } catch (_) {
      // Fallback cập nhật qua RLS
      await client
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('user_id', requesterId)
          .eq('friend_id', user.id);

      await client.from('friendships').upsert({
        'user_id': user.id,
        'friend_id': requesterId,
        'status': 'accepted',
      });
    }
  }

  /// Từ chối lời mời hoặc hủy kết bạn
  Future<void> removeOrRejectFriend(String otherUserId) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    try {
      await client.rpc(
        'remove_or_reject_friend',
        params: {'p_other_user_id': otherUserId},
      );
    } catch (_) {
      // Fallback xóa qua RLS
      await client
          .from('friendships')
          .delete()
          .match({'user_id': user.id, 'friend_id': otherUserId});
      await client
          .from('friendships')
          .delete()
          .match({'user_id': otherUserId, 'friend_id': user.id});
    }
  }

  /// Lắng nghe thay đổi Realtime của quan hệ bạn bè
  Stream<List<Map<String, dynamic>>> watchFriendships() {
    final client = _client;
    if (client == null) return const Stream.empty();
    final user = client.auth.currentUser;
    if (user == null) return const Stream.empty();

    return client
        .from('friendships')
        .stream(primaryKey: ['user_id', 'friend_id'])
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }
}

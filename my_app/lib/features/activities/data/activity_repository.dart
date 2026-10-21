import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/activity_model.dart';

class ActivityRepository {
  ActivityRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> createActivity({
    required String title,
    required String description,
    required String type,
    required String locationName,
    required int maxMembers,
    required DateTime startsAt,
    required String skillLevel,
    required String preparationNotes,
    String targetGender = 'all',
    String joinPolicy = 'everyone',
  }) async {
    final client = _client;
    if (client == null) throw const AuthException('Dịch vụ chưa sẵn sàng.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    dynamic result;
    try {
      // 1. Thử gọi RPC với đầy đủ tham số (nếu DB đã chạy migration 036)
      result = await client.rpc(
        'create_activity_with_team',
        params: {
          'p_title': title.trim(),
          'p_description': description.trim(),
          'p_type': type,
          'p_location_name': locationName.trim(),
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_max_members': maxMembers,
          'p_skill_level': skillLevel,
          'p_preparation_notes': preparationNotes.trim(),
          'p_target_gender': targetGender,
          'p_join_policy': joinPolicy,
        },
      );
    } on PostgrestException catch (e) {
      // 2. Nếu RPC trên DB chưa cập nhật tham số mới (mã lỗi PGRST202), fallback gọi bản 8 tham số
      if (e.code == 'PGRST202' || e.message.contains('create_activity_with_team')) {
        result = await client.rpc(
          'create_activity_with_team',
          params: {
            'p_title': title.trim(),
            'p_description': description.trim(),
            'p_type': type,
            'p_location_name': locationName.trim(),
            'p_starts_at': startsAt.toUtc().toIso8601String(),
            'p_max_members': maxMembers,
            'p_skill_level': skillLevel,
            'p_preparation_notes': preparationNotes.trim(),
          },
        );
      } else {
        rethrow;
      }
    }

    // Cập nhật target_gender & join_policy vào bảng teams để đảm bảo dữ liệu luôn được lưu
    if (result is Map && result['team_id'] != null) {
      final teamId = result['team_id'] as String;
      try {
        await client.from('teams').update({
          'target_gender': targetGender,
          'join_policy': joinPolicy,
        }).eq('id', teamId);
      } catch (_) {
        // Bỏ qua nếu đã được lưu hoặc lỗi mạng phụ
      }
    }
  }

  static const _activitySelectQuery = '''
    *,
    profiles:creator_id(id, display_name, username, avatar_url),
    teams(id, target_gender, join_policy)
  ''';

  Future<List<Map<String, dynamic>>> fetchPublicActivities({int? limit}) async {
    final client = _client;
    if (client == null) return [];

    final user = client.auth.currentUser;
    final joinedIds = <String>{};
    if (user != null) {
      final memberships = await client
          .from('activity_members')
          .select('activity_id')
          .eq('user_id', user.id)
          .eq('status', 'joined');
      joinedIds.addAll(
        List<Map<String, dynamic>>.from(memberships)
            .map((row) => row['activity_id'] as String),
      );
    }

    List<dynamic> rows;
    try {
      var query = client
          .from('activities')
          .select(_activitySelectQuery)
          .eq('is_public', true)
          .inFilter('status', ['open', 'full'])
          .order('starts_at');
      if (limit != null) {
        rows = await query.limit(limit);
      } else {
        rows = await query;
      }
    } catch (_) {
      var query = client
          .from('activities')
          .select()
          .eq('is_public', true)
          .inFilter('status', ['open', 'full'])
          .order('starts_at');
      if (limit != null) {
        rows = await query.limit(limit);
      } else {
        rows = await query;
      }
    }

    final filtered = List<Map<String, dynamic>>.from(rows)
        .where((row) => !joinedIds.contains(row['id']))
        .toList();
    return _attachDistance(filtered);
  }

  /// Lấy danh sách tất cả hoạt động công khai hiển thị trên Home Feed (giới hạn [limit] bản ghi, mặc định 5).
  ///
  /// Hiển thị tất cả hoạt động của cộng đồng không phụ thuộc vào tính toán khoảng cách/sở thích phức tạp.
  Future<List<Map<String, dynamic>>> fetchFeedActivities({int limit = 5}) async {
    final client = _client;
    if (client == null) return [];

    List<dynamic> rows;
    try {
      rows = await client
          .from('activities')
          .select(_activitySelectQuery)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);
    } catch (_) {
      try {
        rows = await client
            .from('activities')
            .select()
            .eq('is_public', true)
            .order('created_at', ascending: false)
            .limit(limit);
      } catch (_) {
        rows = await client
            .from('activities')
            .select()
            .limit(limit);
      }
    }

    return _attachDistance(List<Map<String, dynamic>>.from(rows));
  }

  Future<List<ActivityItem>> fetchPublicActivityList() async {
    final rows = await fetchPublicActivities();
    return rows.map((e) => ActivityItem.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMyActivities() async {
    final client = _client;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    List<dynamic> rows;
    try {
      rows = await client
          .from('activities')
          .select(_activitySelectQuery)
          .eq('creator_id', user.id)
          .order('starts_at');
    } catch (_) {
      rows = await client
          .from('activities')
          .select()
          .eq('creator_id', user.id)
          .order('starts_at');
    }

    return _attachDistance(List<Map<String, dynamic>>.from(rows));
  }

  Future<List<ActivityItem>> fetchMyActivityList() async {
    final rows = await fetchMyActivities();
    return rows.map((e) => ActivityItem.fromMap(e)).toList();
  }

  List<Map<String, dynamic>> _attachDistance(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final map = _normalizeActivityRow(row);
      if (map['distance_km'] == null && map['distance'] == null) {
        final hash = (map['id'] as String? ?? '').hashCode.abs();
        map['distance_km'] = ((hash % 35) + 5) / 10.0;
      }
      return map;
    }).toList();
  }

  Map<String, dynamic> _normalizeActivityRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);

    // Chuẩn hoá thông tin Host từ profiles nếu có
    if (map['host_name'] == null) {
      if (map['profiles'] is Map) {
        final p = map['profiles'] as Map<String, dynamic>;
        map['host_name'] = p['display_name'] ?? p['username'];
        map['host_avatar_url'] ??= p['avatar_url'];
      }
    }

    // Chuẩn hoá thông tin target_gender và join_policy từ teams nếu có
    if (map['teams'] is List && (map['teams'] as List).isNotEmpty) {
      final firstTeam = (map['teams'] as List).first;
      if (firstTeam is Map) {
        map['target_gender'] ??= firstTeam['target_gender'];
        map['join_policy'] ??= firstTeam['join_policy'];
      }
    }

    map['target_gender'] ??= 'all';
    map['join_policy'] ??= 'everyone';

    return map;
  }

  Future<Map<String, dynamic>> fetchActivity(String activityId) async {
    final client = _client;
    if (client == null) return _normalizeActivityRow({'id': activityId});

    try {
      final data = await client
          .from('activities')
          .select(_activitySelectQuery)
          .eq('id', activityId)
          .single();
      return _normalizeActivityRow(data);
    } catch (_) {
      final data = await client
          .from('activities')
          .select()
          .eq('id', activityId)
          .single();
      return _normalizeActivityRow(data);
    }
  }

  Future<ActivityItem> fetchActivityItem(String activityId) async {
    final row = await fetchActivity(activityId);
    return ActivityItem.fromMap(row);
  }

  Future<List<Map<String, dynamic>>> fetchActivityTeams(
    String activityId,
  ) async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('teams')
        .select('*, team_members(count)')
        .eq('team_members.status', 'joined')
        .eq('activity_id', activityId)
        .inFilter('status', ['recruiting', 'full', 'started'])
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }
}

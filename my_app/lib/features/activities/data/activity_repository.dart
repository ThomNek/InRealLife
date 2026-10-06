import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityRepository {
  ActivityRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final result = await _client.rpc(
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

    // Fallback: Nếu backend đang chạy RPC cũ, chủ động update thêm target_gender & join_policy vào bảng teams
    if (result is Map && result['team_id'] != null) {
      final teamId = result['team_id'] as String;
      await _client.from('teams').update({
        'target_gender': targetGender,
        'join_policy': joinPolicy,
      }).eq('id', teamId);
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublicActivities() async {
    final user = _client.auth.currentUser;
    final joinedIds = <String>{};
    if (user != null) {
      final memberships = await _client
          .from('activity_members')
          .select('activity_id')
          .eq('user_id', user.id)
          .eq('status', 'joined');
      joinedIds.addAll(
        List<Map<String, dynamic>>.from(memberships)
            .map((row) => row['activity_id'] as String),
      );
    }
    final rows = await _client
        .from('activities')
        .select()
        .eq('is_public', true)
        .inFilter('status', ['open', 'full'])
        .order('starts_at');
    final filtered = List<Map<String, dynamic>>.from(rows)
        .where((row) => !joinedIds.contains(row['id']))
        .toList();
    return _attachDistance(filtered);
  }

  Future<List<Map<String, dynamic>>> fetchMyActivities() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client
        .from('activities')
        .select()
        .eq('creator_id', user.id)
        .order('starts_at');
    return _attachDistance(List<Map<String, dynamic>>.from(rows));
  }

  List<Map<String, dynamic>> _attachDistance(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      if (map['distance_km'] == null && map['distance'] == null) {
        final hash = (map['id'] as String? ?? '').hashCode.abs();
        map['distance_km'] = ((hash % 35) + 5) / 10.0;
      }
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>> fetchActivity(String activityId) {
    return _client.from('activities').select().eq('id', activityId).single();
  }

  Future<List<Map<String, dynamic>>> fetchActivityTeams(
    String activityId,
  ) async {
    final rows = await _client
        .from('teams')
        .select('*, team_members(count)')
        .eq('team_members.status', 'joined')
        .eq('activity_id', activityId)
        .inFilter('status', ['recruiting', 'full', 'started'])
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }
}

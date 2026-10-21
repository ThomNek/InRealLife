import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/team_model.dart';

class TeamRepository {
  TeamRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<TeamItem>> fetchRecruitingTeamList() async {
    final rows = await fetchRecruitingTeams();
    return rows.map((e) => TeamItem.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRecruitingTeams() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final memberships = await _client
        .from('team_members')
        .select('team_id')
        .eq('user_id', user.id)
        .eq('status', 'joined'); // Fetch the teams the user has joined

    final joinedIds = List<Map<String, dynamic>>.from(memberships)
        .map((row) => row['team_id'] as String)
        .toSet(); // Create a set of team IDs the user has joined

    final requests = await _client
        .from('team_requests')
        .select('team_id, status')
        .eq('user_id', user.id); // Fetch the user's requests to join teams

    final requestStatusByTeam = <String, String>{
      for (final row in List<Map<String, dynamic>>.from(requests))
        row['team_id'] as String: row['status'] as String,
    }; // Create a map of team IDs to request statuses

    final rows = await _client
        .from('teams')
        .select('*, team_members(count)')
        // Chỉ đếm thành viên đang ở trong đội. Các dòng status = left được giữ
        // để lưu lịch sử sau khi rời/kick nhưng không được tính vào sĩ số.
        .eq('team_members.status', 'joined')
        .inFilter('status', ['recruiting', 'full'])
        .order('created_at', ascending: false);

    final result = List<Map<String, dynamic>>.from(rows)
        .where((row) => !joinedIds.contains(row['id']))
        .map((row) {
          final map = Map<String, dynamic>.from(row);
          map['my_request_status'] = requestStatusByTeam[row['id']];
          if (map['distance_km'] == null && map['distance'] == null) {
            final hash = (map['id'] as String? ?? '').hashCode.abs();
            map['distance_km'] = ((hash % 40) + 6) / 10.0;
          }
          return map;
        })
        .toList();
    return result;
  }

  Future<void> createTeam({
    required String name,
    required String description,
    required int maxMembers,
    required String skillLevel,
    required String meetingArea,
    DateTime? meetingAt,
    String targetGender = 'all',
    String joinPolicy = 'everyone',
    String activityType = 'treasure_hunt',
    String? personalTreasureId,
    String meetingCity = '',
    String meetingDistrict = '',
    double? latitude,
    double? longitude,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    await _client.rpc(
      'create_team',
      params: {
        'p_name': name.trim(),
        'p_description': description.trim(),
        'p_max_members': maxMembers,
        'p_skill_level': skillLevel,
        'p_meeting_area': meetingArea.trim(),
        'p_meeting_at': meetingAt?.toUtc().toIso8601String(),
        'p_target_gender': targetGender,
        'p_join_policy': joinPolicy,
        'p_activity_type': activityType,
        'p_personal_treasure_id': personalTreasureId,
        'p_meeting_city': meetingCity.trim(),
        'p_meeting_district': meetingDistrict.trim(),
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchMyTeams() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('team_members')
        .select('''
        team_id,
        role,
        status,
        teams(
          id,
          name,
          description,
          host_id,
          max_members,
          meeting_area,
          meeting_at,
          status
        )
      ''')
        .eq('user_id', user.id)
        .eq('status', 'joined');

    return List<Map<String, dynamic>>.from(rows).map((row) {
      final map = Map<String, dynamic>.from(row);
      final teamData = map['teams'] as Map<String, dynamic>?;
      if (teamData != null && teamData['distance_km'] == null) {
        final hash = (teamData['id'] as String? ?? '').hashCode.abs();
        teamData['distance_km'] = ((hash % 40) + 6) / 10.0;
      }
      return map;
    }).toList();
  }

  Future<void> requestToJoin(String teamId, {String message = ''}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    try {
      await _client.rpc(
        'request_to_join_team',
        params: {'p_team_id': teamId, 'p_message': message.trim()},
      );
    } catch (_) {
      // Fallback chèn trực tiếp vào bảng team_requests nếu RPC chưa được nạp
      await _client.from('team_requests').upsert({
        'team_id': teamId,
        'user_id': user.id,
        'message': message.trim(),
        'status': 'pending',
      });
    }
  }

  Future<Map<String, dynamic>> fetchTeam(String teamId) {
    return _client.from('teams').select().eq('id', teamId).single();
  }

  Future<List<Map<String, dynamic>>> fetchTeamMembers(String teamId) async {
    final rows = await _client
        .from('team_members')
        .select(
          'user_id, role, status, profiles(display_name, avatar_url, is_verified)',
        )
        .eq('team_id', teamId)
        .eq('status', 'joined')
        .order('joined_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> fetchMyRequest(String teamId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _client
        .from('team_requests')
        .select()
        .eq('team_id', teamId)
        .eq('user_id', user.id)
        .maybeSingle();
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<List<Map<String, dynamic>>> watchTeam(String teamId) =>
      _client.from('teams').stream(primaryKey: ['id']).eq('id', teamId);

  Stream<List<Map<String, dynamic>>> watchTeamMembers(String teamId) => _client
      .from('team_members')
      .stream(primaryKey: ['team_id', 'user_id'])
      .eq('team_id', teamId);

  Stream<List<Map<String, dynamic>>> watchTeamRequests(String teamId) => _client
      .from('team_requests')
      .stream(primaryKey: ['id'])
      .eq('team_id', teamId);

  Future<List<Map<String, dynamic>>> fetchPendingRequests(String teamId) async {
    final rows = await _client
        .from('team_requests')
        .select(
          'id, user_id, message, status, profiles(display_name, avatar_url)',
        )
        .eq('team_id', teamId)
        .eq('status', 'pending')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> approveRequest(String requestId) {
    return _client.rpc(
      'approve_team_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> rejectRequest(String requestId) {
    return _client.rpc(
      'reject_team_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> kickMember(String teamId, String userId) {
    return _client.rpc(
      'kick_team_member',
      params: {'p_team_id': teamId, 'p_user_id': userId},
    );
  }

  Future<void> cancelJoinRequest(String teamId) {
    return _client.rpc('cancel_team_request', params: {'p_team_id': teamId});
  }

  Future<void> leaveTeam(String teamId) {
    return _client.rpc('leave_team', params: {'p_team_id': teamId});
  }

  Future<Map<String, dynamic>?> findHostTeamForActivity(
    String activityId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final rows = await _client
        .from('teams')
        .select()
        .eq('activity_id', activityId)
        .eq('host_id', user.id)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isNotEmpty ? list.first : null;
  }
}

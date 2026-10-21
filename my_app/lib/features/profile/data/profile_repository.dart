import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;

    return client.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final client = _client;
    if (client == null) return null;
    return client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  Future<UserProfile?> fetchProfileModel(String userId) async {
    final data = await fetchProfile(userId);
    return data != null ? UserProfile.fromMap(data) : null;
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    String query = '',
    int limit = 40,
  }) async {
    final client = _client;
    if (client == null) return [];
    final currentUserId = client.auth.currentUser?.id;

    var req = client.from('profiles').select();
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      req = req.or('display_name.ilike.%$trimmed%,username.ilike.%$trimmed%,city.ilike.%$trimmed%');
    }

    final rows = await req
        .order('exp', ascending: false)
        .limit(limit);

    final list = List<Map<String, dynamic>>.from(rows);
    if (currentUserId != null) {
      // Đưa bản thân ra khỏi danh sách tìm bạn hoặc để ở cuối
      list.sort((a, b) {
        if (a['id'] == currentUserId) return 1;
        if (b['id'] == currentUserId) return -1;
        return 0;
      });
    }
    return list;
  }

  Future<List<UserProfile>> searchUsersModel({
    String query = '',
    int limit = 40,
  }) async {
    final rows = await searchUsers(query: query, limit: limit);
    return rows.map((e) => UserProfile.fromMap(e)).toList();
  }

  Future<UserProfile?> fetchCurrentProfileModel() async {
    final data = await fetchCurrentProfile();
    return data != null ? UserProfile.fromMap(data) : null;
  }

  Stream<Map<String, dynamic>?> watchCurrentProfile() {
    final client = _client;
    if (client == null) return Stream.value(null);
    final user = client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Stream<UserProfile?> watchCurrentProfileModel() {
    return watchCurrentProfile().map(
      (data) => data != null ? UserProfile.fromMap(data) : null,
    );
  }

  Future<void> updateCurrentProfile({
    required String displayName,
    required String username,
    required String avatarUrl,
    required String bio,
    required String city,
    required List<String> interests,
    required int? birthYear,
    required String profileVisibility,
    String gender = 'other',
  }) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final normalizedDisplayName = displayName.trim();
    final normalizedUsername = username.trim();
    final normalizedAvatarUrl = avatarUrl.trim();

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'display_name': normalizedDisplayName,
        'username': normalizedUsername.isEmpty ? null : normalizedUsername,
        'avatar_url': normalizedAvatarUrl.isEmpty ? null : normalizedAvatarUrl,
        'bio': bio.trim(),
        'city': city.trim(),
        'interests': interests,
        'birth_year': birthYear,
        'profile_visibility': profileVisibility,
        'gender': gender,
      });
    } on PostgrestException catch (e) {
      // Nếu schema cache chưa có birth_year hoặc gender, fallback loại bỏ các trường chưa được migrate
      if (e.message.contains('birth_year') || e.message.contains('gender') || e.code == 'PGRST204') {
        final fallbackMap = <String, dynamic>{
          'id': user.id,
          'display_name': normalizedDisplayName,
          'username': normalizedUsername.isEmpty ? null : normalizedUsername,
          'avatar_url': normalizedAvatarUrl.isEmpty ? null : normalizedAvatarUrl,
          'bio': bio.trim(),
          'city': city.trim(),
          'interests': interests,
        };
        if (!e.message.contains('birth_year')) {
          fallbackMap['birth_year'] = birthYear;
        }
        if (!e.message.contains('profile_visibility')) {
          fallbackMap['profile_visibility'] = profileVisibility;
        }
        if (!e.message.contains('gender')) {
          fallbackMap['gender'] = gender;
        }
        await client.from('profiles').upsert(fallbackMap);
      } else {
        rethrow;
      }
    }

    // Auth metadata chỉ là bản sao nhỏ phục vụ các thành phần tài khoản toàn
    // cục (menu avatar/sidebar). Hồ sơ đầy đủ vẫn lấy từ public.profiles.
    await client.auth.updateUser(
      UserAttributes(
        data: {
          'display_name': normalizedDisplayName,
          'avatar_url': normalizedAvatarUrl.isEmpty
              ? null
              : normalizedAvatarUrl,
          'gender': gender,
        },
      ),
    );
  }

  Future<void> completeOnboarding({
    required List<String> interests,
    required String comfortPreference,
    required int travelRadiusKm,
  }) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? const {});
    final displayName =
        (metadata['display_name'] as String?)?.trim().isNotEmpty == true
        ? (metadata['display_name'] as String).trim()
        : (user.email?.split('@').first ?? 'Người dùng');
    final completedAt = DateTime.now().toUtc().toIso8601String();

    // Upsert giúp luồng này vẫn hoạt động nếu trigger tạo profile chưa được
    // cài trên một môi trường Supabase mới.
    await client.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
      'interests': interests,
    });

    // Các lựa chọn trải nghiệm không dùng để phân quyền nên có thể lưu trong
    // user metadata cho tới khi schema riêng cho preferences được triển khai.
    await client.auth.updateUser(
      UserAttributes(
        data: {
          ...metadata,
          'display_name': displayName,
          'comfort_preference': comfortPreference,
          'travel_radius_km': travelRadiusKm,
          'onboarding_completed_at': completedAt,
        },
      ),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return _client.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Stream<Map<String, dynamic>?> watchCurrentProfile() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : rows.first);
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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final normalizedDisplayName = displayName.trim();
    final normalizedUsername = username.trim();
    final normalizedAvatarUrl = avatarUrl.trim();

    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': normalizedDisplayName,
      // username là tùy chọn. PostgreSQL UNIQUE cho phép nhiều NULL nhưng chỉ
      // cho phép một chuỗi rỗng, vì vậy phải đổi ô trống thành NULL.
      'username': normalizedUsername.isEmpty ? null : normalizedUsername,
      'avatar_url': normalizedAvatarUrl.isEmpty ? null : normalizedAvatarUrl,
      'bio': bio.trim(),
      'city': city.trim(),
      'interests': interests,
      'birth_year': birthYear,
      'profile_visibility': profileVisibility,
    });

    // Auth metadata chỉ là bản sao nhỏ phục vụ các thành phần tài khoản toàn
    // cục (menu avatar/sidebar). Hồ sơ đầy đủ vẫn lấy từ public.profiles.
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'display_name': normalizedDisplayName,
          'avatar_url': normalizedAvatarUrl.isEmpty
              ? null
              : normalizedAvatarUrl,
        },
      ),
    );
  }

  Future<void> completeOnboarding({
    required List<String> interests,
    required String comfortPreference,
    required int travelRadiusKm,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? const {});
    final displayName =
        (metadata['display_name'] as String?)?.trim().isNotEmpty == true
        ? (metadata['display_name'] as String).trim()
        : (user.email?.split('@').first ?? 'Người dùng');
    final completedAt = DateTime.now().toUtc().toIso8601String();

    // Upsert giúp luồng này vẫn hoạt động nếu trigger tạo profile chưa được
    // cài trên một môi trường Supabase mới.
    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
      'interests': interests,
    });

    // Các lựa chọn trải nghiệm không dùng để phân quyền nên có thể lưu trong
    // user metadata cho tới khi schema riêng cho preferences được triển khai.
    await _client.auth.updateUser(
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

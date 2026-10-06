import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository cho tính năng Radar — khám phá hoạt động và kho báu gần bạn.
///
/// Hiện tại RadarPage hiển thị UI mô phỏng (static data). Lớp này cung cấp
/// tầng data để kết nối Supabase khi tính năng lọc theo vị trí và tìm kiếm
/// hoạt động gần bạn được triển khai.
///
/// Nguyên tắc an toàn vị trí (bắt buộc tuân thủ khi implement thật):
/// - Không lưu hoặc log tọa độ GPS chính xác của người dùng.
/// - Chỉ truyền bán kính tìm kiếm (radius_km) lên server — server thực hiện
///   spatial query, không để client tự lọc tọa độ.
/// - Không bao giờ trả về tọa độ GPS chính xác của người dùng khác.
class RadarRepository {
  RadarRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Tìm hoạt động và kho báu trong bán kính [radiusKm] tính từ vị trí
  /// trung tâm [latCenter], [lngCenter].
  ///
  /// TODO: triển khai PostGIS extension + RPC `find_nearby_activities` sau khi
  /// production database được bật spatial indexing.
  Future<List<Map<String, dynamic>>> fetchNearbyActivities({
    required double latCenter,
    required double lngCenter,
    double radiusKm = 5.0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    // Placeholder — trả về danh sách trống cho đến khi RPC sẵn sàng.
    return [];
  }

  /// Tìm hoạt động theo bộ lọc văn bản (tên địa điểm, loại hoạt động).
  /// TODO: kết nối Supabase full-text search hoặc RPC tìm kiếm.
  Future<List<Map<String, dynamic>>> searchActivities(String query) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    if (query.trim().isEmpty) return [];

    final rows = await _client
        .from('activities')
        .select()
        .eq('is_public', true)
        .ilike('title', '%${query.trim()}%')
        .inFilter('status', ['open', 'full'])
        .order('starts_at')
        .limit(30);
    return List<Map<String, dynamic>>.from(rows);
  }
}

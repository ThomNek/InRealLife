import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository cho tính năng An toàn — chặn người dùng và báo cáo sự cố.
///
/// SafetyCenterPage hiện tại chỉ hiển thị hướng dẫn tĩnh. Lớp này cung cấp
/// tầng data để triển khai các tính năng an toàn cốt lõi kết nối với Supabase:
/// chặn người dùng, báo cáo nội dung/sự cố và chia sẻ lịch hoạt động với
/// người thân.
class SafetyRepository {
  SafetyRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Lấy danh sách người dùng hiện tại đã chặn.
  /// TODO: kết nối bảng `blocked_users` sau khi migration được triển khai.
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    // Placeholder — trả về danh sách trống cho đến khi schema sẵn sàng.
    return [];
  }

  /// Chặn người dùng [targetUserId].
  /// TODO: triển khai RPC `block_user`.
  Future<void> blockUser(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    if (targetUserId == user.id) {
      throw ArgumentError('Không thể tự chặn chính mình.');
    }
    throw UnimplementedError('blockUser chưa được triển khai.');
  }

  /// Bỏ chặn người dùng [targetUserId].
  /// TODO: triển khai RPC `unblock_user`.
  Future<void> unblockUser(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    throw UnimplementedError('unblockUser chưa được triển khai.');
  }

  /// Báo cáo người dùng hoặc nội dung vi phạm.
  ///
  /// [targetType] là loại đối tượng báo cáo: 'user', 'activity', 'team',
  /// 'message', 'post'.
  ///
  /// TODO: triển khai RPC `submit_report` + bảng `reports`.
  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
    String? detail,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    if (reason.trim().isEmpty) throw ArgumentError('Lý do không được để trống.');
    throw UnimplementedError('submitReport chưa được triển khai.');
  }

  /// Kiểm tra xem người dùng [targetUserId] có bị chặn không.
  Future<bool> isBlocked(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    // TODO: query bảng blocked_users sau khi schema sẵn sàng.
    return false;
  }
}

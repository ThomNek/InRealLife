import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository cho tính năng Bài đăng có mục đích (Purpose-driven Posts).
///
/// Các loại bài: 'find_team' (tìm đồng đội), 'share_clue' (chia sẻ manh mối),
/// 'trade_piece' (đổi mảnh ghép), 'achievement' (thành tích đã xác minh).
///
/// Bài đăng trong Treasure IRL có thời hạn (expires_at) và phải dẫn đến
/// hành động ngoài đời — không phải nội dung thu thập like vô thời hạn.
class PostRepository {
  PostRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const maxContentLength = 500;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Lấy bài đăng công khai chưa hết hạn, sắp xếp theo mới nhất.
  /// TODO: kết nối bảng `posts` sau khi migration được triển khai.
  Future<List<Map<String, dynamic>>> fetchPublicPosts({
    String? type,
    int limit = 20,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    // Placeholder — trả về danh sách trống cho đến khi schema sẵn sàng.
    return [];
  }

  /// Tạo bài đăng mới có mục đích.
  ///
  /// [type] phải là một trong: 'find_team', 'share_clue', 'trade_piece',
  /// 'achievement'.
  ///
  /// [expiresAt] mặc định là 7 ngày nếu không truyền — bài tìm đội thường
  /// chỉ có ý nghĩa trong một khoảng thời gian ngắn.
  ///
  /// TODO: triển khai RPC `create_post` + bảng `posts`.
  Future<void> createPost({
    required String type,
    required String content,
    String? imageUrl,
    String? city,
    String? relatedPieceId,
    String? visibility,
    DateTime? expiresAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final text = content.trim();
    if (text.isEmpty) throw ArgumentError('Nội dung bài đăng không được trống.');
    if (text.length > maxContentLength) {
      throw ArgumentError(
        'Nội dung bài đăng không được vượt quá $maxContentLength ký tự.',
      );
    }

    const allowedTypes = {
      'find_team',
      'share_clue',
      'trade_piece',
      'achievement',
    };
    if (!allowedTypes.contains(type)) {
      throw ArgumentError(
        'Loại bài không hợp lệ: $type. Phải là một trong $allowedTypes.',
      );
    }

    throw UnimplementedError('createPost chưa được triển khai.');
  }

  /// Xóa bài đăng của chính mình.
  /// TODO: triển khai RPC `delete_post`.
  Future<void> deletePost(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    throw UnimplementedError('deletePost chưa được triển khai.');
  }

  /// Báo cáo bài đăng vi phạm.
  /// TODO: kết nối SafetyRepository.submitReport.
  Future<void> reportPost(String postId, String reason) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    if (reason.trim().isEmpty) throw ArgumentError('Lý do không được để trống.');
    throw UnimplementedError('reportPost chưa được triển khai.');
  }
}

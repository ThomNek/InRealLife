import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository cho tính năng Kho vật phẩm & Chợ mảnh ghép.
///
/// Hiện tại dữ liệu vật phẩm chưa được kết nối Supabase (schema chưa triển
/// khai). Lớp này đóng vai trò "placeholder" để UI có thể inject
/// InventoryRepository thay vì gọi Supabase trực tiếp, giúp dễ dàng kết nối
/// thật hoặc mock trong test.
///
/// Khi schema `user_pieces`, `trade_offers` và `trade_transactions` sẵn sàng,
/// chỉ cần điền phần thân method mà không cần sửa UI.
class InventoryRepository {
  InventoryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Lấy toàn bộ vật phẩm của người dùng hiện tại.
  /// TODO: kết nối bảng `user_pieces` sau khi migration được triển khai.
  Future<List<Map<String, dynamic>>> fetchMyPieces() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    // Placeholder — trả về danh sách trống cho đến khi schema sẵn sàng.
    return [];
  }

  /// Lấy danh sách đề nghị trao đổi mảnh ghép đang mở.
  /// TODO: kết nối bảng `trade_offers` sau khi migration được triển khai.
  Future<List<Map<String, dynamic>>> fetchOpenTradeOffers() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    return [];
  }

  /// Tạo đề nghị trao đổi mảnh ghép.
  /// TODO: triển khai RPC `create_trade_offer`.
  Future<void> createTradeOffer({
    required String offeredPieceId,
    required String wantedPieceId,
    required String receiverUserId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    // TODO: await _client.rpc('create_trade_offer', params: {...});
    throw UnimplementedError(
      'createTradeOffer chưa được triển khai — cần migration schema.',
    );
  }

  /// Xác nhận giao dịch trao đổi mảnh ghép.
  /// TODO: triển khai RPC `confirm_trade_offer`.
  Future<void> confirmTradeOffer(String offerId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    throw UnimplementedError(
      'confirmTradeOffer chưa được triển khai — cần migration schema.',
    );
  }
}

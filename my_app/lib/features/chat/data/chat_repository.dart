import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  ChatRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _messageWindowSize = 200;
  static const maxMessageLength = 2000;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchPeople() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('profiles')
        .select('id, display_name, username, avatar_url, city')
        .neq('id', user.id)
        .order('display_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> openDirectConversation(String otherUserId) async {
    final result = await _client.rpc(
      'get_or_create_direct_conversation',
      params: {'p_other_user_id': otherUserId},
    );
    return result as String;
  }

  Future<String> openTeamConversation(String teamId) async {
    final result = await _client.rpc(
      'get_or_create_team_conversation',
      params: {'p_team_id': teamId},
    );
    return result as String;
  }

  Future<List<Map<String, dynamic>>> fetchInbox() async {
    final rows = await _client.rpc('fetch_chat_inbox');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> markRead(String conversationId) {
    return _client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        // Lấy cửa sổ mới nhất để phòng chat lâu năm không render hàng nghìn
        // widget. Đảo lại thành tăng dần vì các màn chat coi rows.last là tin
        // mới nhất và tự hiển thị danh sách theo chiều ngược.
        .order('created_at', ascending: false)
        .limit(_messageWindowSize)
        .map((rows) => List<Map<String, dynamic>>.from(rows.reversed));
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final text = content.trim();
    if (text.isEmpty) return;
    if (text.length > maxMessageLength) {
      throw ArgumentError('Tin nhắn không được vượt quá 2.000 ký tự.');
    }

    await _client.rpc(
      'send_message',
      params: {'p_conversation_id': conversationId, 'p_content': text},
    );
  }
}

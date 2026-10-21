import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_models.dart';

class ChatRepository {
  ChatRepository({SupabaseClient? client}) : _client = client ?? _safeClient();

  final SupabaseClient? _client;
  static const _messageWindowSize = 200;
  static const maxMessageLength = 2000;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchPeople() async {
    final client = _client;
    if (client == null) return [];
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final rows = await client
          .from('profiles')
          .select('id, display_name, username, avatar_url, city')
          .neq('id', user.id)
          .order('display_name');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<String> openDirectConversation(String otherUserId) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final result = await client.rpc(
      'get_or_create_direct_conversation',
      params: {'p_other_user_id': otherUserId},
    );
    return result as String;
  }

  Future<String> openTeamConversation(String teamId) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final result = await client.rpc(
      'get_or_create_team_conversation',
      params: {'p_team_id': teamId},
    );
    return result as String;
  }

  Future<List<ChatConversation>> fetchInboxConversations() async {
    final rows = await fetchInbox();
    return rows.map((e) => ChatConversation.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchInbox() async {
    final client = _client;
    if (client == null) return [];
    try {
      final rows = await client.rpc('fetch_chat_inbox');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> markRead(String conversationId) {
    final client = _client;
    if (client == null) return Future.value();
    return client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    final client = _client;
    if (client == null) return const Stream.empty();
    return client
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

  Stream<List<ChatMessage>> watchMessagesList(String conversationId) {
    return watchMessages(conversationId)
        .map((rows) => rows.map((e) => ChatMessage.fromMap(e)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final client = _client;
    if (client == null) throw const AuthException('Bạn chưa đăng nhập.');
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');

    final text = content.trim();
    if (text.isEmpty) return;
    if (text.length > maxMessageLength) {
      throw ArgumentError('Tin nhắn không được vượt quá 2.000 ký tự.');
    }

    await client.rpc(
      'send_message',
      params: {'p_conversation_id': conversationId, 'p_content': text},
    );
  }
}

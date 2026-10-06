import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchMine() {
    final client = _client;
    if (client == null) return Stream.value(const []);
    final user = client.auth.currentUser;
    if (user == null) return Stream.value(const []);

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  Future<void> markRead(String notificationId) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const AuthException('Bạn chưa đăng nhập.');
    }
    await client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllRead() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw const AuthException('Bạn chưa đăng nhập.');
    }
    await client.rpc('mark_all_notifications_read');
  }
}

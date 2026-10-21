import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_model.dart';

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

  Stream<List<NotificationItem>> watchMineModels() {
    return watchMine().map(
      (rows) => rows.map((e) => NotificationItem.fromMap(e)).toList(),
    );
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
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AuthException('Bạn chưa đăng nhập.');
    }
    try {
      await client.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );
    } catch (_) {
      // Fallback update trực tiếp nếu RPC chưa có
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', notificationId)
          .eq('user_id', user.id);
    }
  }

  Future<void> markAllRead() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AuthException('Bạn chưa đăng nhập.');
    }
    try {
      await client.rpc('mark_all_notifications_read');
    } catch (_) {
      // Fallback update trực tiếp nếu RPC chưa có
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', user.id)
          .isFilter('read_at', null);
    }
  }
}

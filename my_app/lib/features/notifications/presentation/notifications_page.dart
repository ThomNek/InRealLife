import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../chat/presentation/conversation_page.dart';
import '../data/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.repository, this.initialStream});

  final NotificationRepository? repository;
  final Stream<List<Map<String, dynamic>>>? initialStream;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  late final NotificationRepository _repository;
  late Stream<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.repository ?? NotificationRepository();
    _notifications = widget.initialStream ?? _repository.watchMine();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _reconnect();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Thông báo',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: 'Kết nối lại',
          onPressed: _reconnect,
          icon: const Icon(Icons.refresh_rounded),
        ),
        TextButton(onPressed: _markAllRead, child: const Text('Đã đọc hết')),
      ],
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không thể tải thông báo: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _reconnect,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return const Center(
            child: Text(
              'Bạn chưa có thông báo.',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: rows.length,
          itemBuilder: (context, index) =>
              _Notice(data: rows[index], onTap: () => _open(rows[index])),
        );
      },
    ),
  );

  void _reconnect() {
    setState(() {
      _notifications = _repository.watchMine();
    });
  }

  Future<void> _markAllRead() async {
    try {
      await _repository.markAllRead();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật thông báo: $error')),
      );
    }
  }

  Future<void> _open(Map<String, dynamic> notification) async {
    try {
      if (notification['read_at'] == null) {
        await _repository.markRead(notification['id'] as String);
      }
      if (!mounted) return;
      final entityType = notification['entity_type'] as String?;
      final entityId = notification['entity_id'] as String?;
      if (entityType == 'team' && entityId != null) {
        await Navigator.pushNamed(
          context,
          '/teams/detail',
          arguments: entityId,
        );
      } else if (entityType == 'conversation' && entityId != null) {
        await Navigator.pushNamed(
          context,
          '/chat',
          arguments: ConversationPageArgs(
            conversationId: entityId,
            title: notification['title'] as String?,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở thông báo: $error')));
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'system';
    final unread = data['read_at'] == null;
    final visual = _visual(type);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: unread ? AppColors.surfaceAlt : AppColors.surface,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: visual.$2.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(visual.$1, color: visual.$2),
        ),
        title: Text(
          data['title'] as String? ?? 'Thông báo',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          data['body'] as String? ?? '',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: unread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  (IconData, Color) _visual(String type) => switch (type) {
    'team_request' => (Icons.group_add_rounded, AppColors.cyan),
    'team_request_approved' => (Icons.check_circle_rounded, Colors.greenAccent),
    'team_request_rejected' => (Icons.cancel_outlined, Colors.redAccent),
    'team_kicked' => (Icons.person_remove_outlined, Colors.redAccent),
    'direct_message' ||
    'team_message' => (Icons.chat_bubble_outline_rounded, AppColors.orange),
    _ => (Icons.notifications_none_rounded, const Color(0xFFFFD22E)),
  };
}

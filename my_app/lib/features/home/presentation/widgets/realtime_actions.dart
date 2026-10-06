import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../notifications/data/notification_repository.dart';

class HomeRealtimeActions extends StatefulWidget {
  const HomeRealtimeActions({super.key});

  @override
  State<HomeRealtimeActions> createState() => _HomeRealtimeActionsState();
}

class _HomeRealtimeActionsState extends State<HomeRealtimeActions>
    with WidgetsBindingObserver {
  late Stream<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = NotificationRepository().watchMine();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _notifications = NotificationRepository().watchMine();
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notifications,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          final unreadNotifications =
              rows.where((row) => row['read_at'] == null).length;
          final unreadMessages = rows
              .where(
                (row) =>
                    row['read_at'] == null &&
                    (row['type'] == 'direct_message' ||
                        row['type'] == 'team_message'),
              )
              .length;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgeActionButton(
                tooltip: 'Thông báo',
                icon: Icons.notifications_none_rounded,
                unread: unreadNotifications,
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              const SizedBox(width: 8),
              _BadgeActionButton(
                tooltip: 'Tin nhắn',
                icon: Icons.chat_bubble_outline_rounded,
                unread: unreadMessages,
                onPressed: () => Navigator.pushNamed(context, '/chat'),
              ),
            ],
          );
        },
      );
}

class _BadgeActionButton extends StatelessWidget {
  const _BadgeActionButton({
    required this.tooltip,
    required this.icon,
    required this.unread,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton.filledTonal(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.muted,
              fixedSize: const Size(48, 48),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      );
}

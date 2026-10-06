import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Thanh tác vụ dưới cùng của trang Chi tiết hoạt động (Host vs Member)
class ActivityDetailBottomBar extends StatelessWidget {
  const ActivityDetailBottomBar({
    super.key,
    required this.hostTeam,
    required this.teams,
  });

  final Map<String, dynamic>? hostTeam;
  final List<Map<String, dynamic>> teams;

  @override
  Widget build(BuildContext context) {
    final isHost = hostTeam != null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/check-in'),
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Săn cá nhân'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isHost
                  ? FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/teams/detail',
                        arguments: hostTeam!['id'] as String?,
                      ),
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: const Text('Quản lý đội của tôi'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: teams.isEmpty
                          ? () => Navigator.pushNamed(context, '/activities')
                          : () => Navigator.pushNamed(
                              context,
                              '/teams/detail',
                              arguments: teams.first['id'] as String?,
                            ),
                      icon: const Icon(Icons.group_add_rounded),
                      label: const Text('Tham gia nhóm'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

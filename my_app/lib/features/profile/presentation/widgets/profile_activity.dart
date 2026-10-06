import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileActivity extends StatelessWidget {
  const ProfileActivity({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'HOẠT ĐỘNG GẦN ĐÂY',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _ActivityItem(
              icon: Icons.emoji_events_rounded,
              title: 'Hoàn thành Kho báu Hoàng Hôn',
              meta: 'Nhận 500 EXP · 2 ngày trước',
            ),
            Divider(height: 24),
            _ActivityItem(
              icon: Icons.groups_rounded,
              title: 'Tham gia đội Rương Thư Viện',
              meta: 'Cùng 3 thợ săn · 5 ngày trước',
            ),
            Divider(height: 24),
            _ActivityItem(
              icon: Icons.extension_rounded,
              title: 'Tìm thấy mảnh ghép B7',
              meta: 'Công viên Trung tâm · 1 tuần trước',
            ),
          ],
        ),
      );
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

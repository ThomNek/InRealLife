import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Hàng chip thông tin ngày giờ, trạng thái, trình độ và số lượng thành viên
class ActivityDetailInfoChips extends StatelessWidget {
  const ActivityDetailInfoChips({
    super.key,
    required this.startsAtLabel,
    required this.statusLabel,
    required this.skillLevelLabel,
    required this.memberCount,
    required this.maxMembers,
  });

  final String startsAtLabel;
  final String statusLabel;
  final String skillLevelLabel;
  final int memberCount;
  final int maxMembers;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.calendar_today_outlined,
          text: startsAtLabel,
        ),
        _InfoChip(
          icon: Icons.signal_cellular_alt_rounded,
          text: '$statusLabel · $skillLevelLabel',
        ),
        _InfoChip(
          icon: Icons.groups_outlined,
          text: '$memberCount/$maxMembers người',
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 17, color: AppColors.cyan),
        label: Text(text),
      );
}

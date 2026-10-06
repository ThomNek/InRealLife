import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Khối tiêu đề thông tin đội (Tên đội, sĩ số thành viên, mô tả)
class TeamDetailHeader extends StatelessWidget {
  const TeamDetailHeader({
    super.key,
    required this.name,
    required this.memberCount,
    required this.maxMembers,
    required this.description,
  });

  final String name;
  final int memberCount;
  final int maxMembers;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            '$memberCount/$maxMembers thành viên',
            style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

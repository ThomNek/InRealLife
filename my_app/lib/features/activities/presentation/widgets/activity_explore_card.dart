import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Một thẻ hoạt động trong trang Khám phá.
///
/// Chỉ nhận dữ liệu và callback để vẽ UI; không giữ state hay gọi database.
class ActivityExploreCard extends StatelessWidget {
  const ActivityExploreCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.type,
    required this.meta,
    required this.people,
    required this.level,
    this.hostName,
    this.targetGender = 'all',
    this.joinPolicy = 'everyone',
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String type;
  final String meta;
  final String people;
  final String level;
  final String? hostName;
  final String targetGender;
  final String joinPolicy;
  final VoidCallback onTap;

  static String _genderLabel(String gender) {
    switch (gender) {
      case 'female_only':
        return '👩 Chỉ nữ';
      case 'male_only':
        return '👨 Chỉ nam';
      default:
        return '👥 Nam & Nữ';
    }
  }

  static String _policyLabel(String policy) {
    switch (policy) {
      case 'friends_only':
        return '🤝 Chỉ bạn bè';
      default:
        return '🌐 Mọi người';
    }
  }

  Widget _buildTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      );

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'CÒN CHỖ',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              type,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 7),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(meta, style: const TextStyle(color: AppColors.muted)),
            if (hostName != null && hostName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Host: $hostName',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildTag(_genderLabel(targetGender)),
                _buildTag(_policyLabel(joinPolicy)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 17, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(people),
                const Spacer(),
                Text(level, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

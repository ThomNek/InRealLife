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
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String type;
  final String meta;
  final String people;
  final String level;
  final VoidCallback onTap;

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
            const SizedBox(height: 9),
            Text(meta, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 13),
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    final openedTreasures =
        (profile?['opened_treasures_count'] as num?)?.toInt() ?? 12;
    final totalDistance =
        (profile?['total_distance_km'] as num?)?.toDouble() ?? 48.5;
    final exploredPlaces =
        (profile?['explored_places_count'] as num?)?.toInt() ?? 15;
    final reputation = (profile?['reputation_score'] as num?)?.toInt() ?? 100;
    final ratingAvg = (profile?['rating_avg'] as num?)?.toDouble() ?? 4.9;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.orange,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'THỐNG KÊ THỢ SĂN (IRL)',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _StatItem(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFFFFD428),
                value: '$openedTreasures rương',
                label: 'Kho báu đã mở',
              ),
              _StatItem(
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.cyan,
                value: '${totalDistance.toStringAsFixed(1)} km',
                label: 'Quãng đường đi',
              ),
              _StatItem(
                icon: Icons.explore_outlined,
                iconColor: const Color(0xFFC084FC),
                value: '$exploredPlaces địa điểm',
                label: 'Nhật ký khám phá',
              ),
              _StatItem(
                icon: Icons.verified_user_outlined,
                iconColor: Colors.greenAccent,
                value: '$reputationđ · ⭐${ratingAvg.toStringAsFixed(1)}',
                label: 'Uy tín & Đánh giá',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

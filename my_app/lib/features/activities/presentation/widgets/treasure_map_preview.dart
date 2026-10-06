import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Bản đồ xem trước vị trí rương kho báu cá nhân (tạm)
class TreasureMapPreview extends StatelessWidget {
  const TreasureMapPreview({
    super.key,
    required this.treasureName,
    required this.location,
    required this.distance,
  });

  final String treasureName;
  final String location;
  final String distance;

  @override
  Widget build(BuildContext context) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF161B2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan.withValues(alpha: .4)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFFD428),
                    size: 36,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    treasureName,
                    style: const TextStyle(
                      color: Color(0xFFFFD428),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Cách bạn $distance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

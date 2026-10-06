import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileShowcase extends StatelessWidget {
  const ProfileShowcase({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    // 3 huy hiệu mặc định đã ghim + 2 ô trống với dấu '+'
    final badges = <Map<String, String>>[
      {'icon': '🌅', 'label': 'Hoàng hôn'},
      {'icon': '🤝', 'label': 'Đồng đội'},
      {'icon': '🔍', 'label': 'Tinh mắt'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.military_tech_rounded,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'HUY HIỆU NỔI BẬT (5 Ô)',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ],
              ),
              Text(
                '${badges.length}/5',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < 5; i++)
                if (i < badges.length)
                  _BadgeSlot(
                    icon: badges[i]['icon']!,
                    label: badges[i]['label']!,
                  )
                else
                  _EmptyBadgeSlot(
                    index: i + 1,
                    onTap: () => _onAddBadge(context, i + 1),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  static void _onAddBadge(BuildContext context, int slotNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bấm dấu (+) để ghim Huy hiệu vào ô số $slotNumber'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _BadgeSlot extends StatelessWidget {
  const _BadgeSlot({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange.withValues(alpha: .4)),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _EmptyBadgeSlot extends StatelessWidget {
  const _EmptyBadgeSlot({required this.index, required this.onTap});

  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF191D2C),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.muted,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm +',
              style: TextStyle(
                color: AppColors.muted.withValues(alpha: .7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

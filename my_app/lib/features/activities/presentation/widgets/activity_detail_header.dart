import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const _banner = 'assets/images/banners/AnhSuoi.jpg';

/// Header SliverAppBar của trang chi tiết hoạt động
class ActivityDetailHeader extends StatelessWidget {
  const ActivityDetailHeader({
    super.key,
    required this.title,
    required this.typeLabel,
  });

  final String title;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bookmark_border_rounded),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_banner, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), AppColors.background],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

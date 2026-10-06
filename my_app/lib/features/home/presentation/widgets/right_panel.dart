import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/domain/profile_progress.dart';

const String _logoAsset = 'assets/images/logos/Logo1.png';

const TextStyle _sectionLabelStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w900,
);

class HomeRightPanel extends StatelessWidget {
  const HomeRightPanel({super.key, required this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        primary: false,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        child: Column(
          children: [
            _accountCard(profile),
            const SizedBox(height: 14),
            const _RightPanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THỢ SĂN GẦN BẠN', style: _sectionLabelStyle),
                  SizedBox(height: 12),
                  _Friend(name: 'Nam', status: 'Đang đi săn', online: true),
                  _Friend(name: 'Linh', status: 'Rảnh', online: true),
                  _Friend(name: 'Tùng', status: 'Offline', online: false),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _RightPanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ĐỒNG ĐỘI NỔI BẬT', style: _sectionLabelStyle),
                  SizedBox(height: 12),
                  _Rank(icon: '🤝', name: 'AlexNguyen', points: '1280'),
                  _Rank(icon: '🧩', name: 'MinhLee', points: '1140'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _RightPanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🧩', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bộ Hoàng Hôn',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Đã có 3/4 mảnh',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tìm mảnh B7 →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _accountCard(Map<String, dynamic>? profile) {
    final progress = ProfileProgress.fromProfile(profile);
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}

    final profileName = profile?['display_name'] as String?;
    final metadataName = user?.userMetadata?['display_name'] as String?;
    final name = profileName?.trim().isNotEmpty == true
        ? profileName
        : metadataName;

    final profileAvatar = profile?['avatar_url'] as String?;
    final metadataAvatar = user?.userMetadata?['avatar_url'] as String?;
    final avatarUrl = profileAvatar?.trim().isNotEmpty == true
        ? profileAvatar
        : metadataAvatar;

    return _RightPanelCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFD700),
            ),
            child: UserAvatar(
              radius: 31,
              fallbackAsset: _logoAsset,
              avatarUrl: avatarUrl,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name?.trim().isNotEmpty == true ? name!.trim() : 'Tài khoản của tôi',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            'Lvl ${progress.level}',
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.fraction,
            color: AppColors.cyan,
            backgroundColor: AppColors.surfaceAlt,
          ),
          const SizedBox(height: 5),
          Text(
            '${progress.exp} / ${progress.target} EXP',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RightPanelCard extends StatelessWidget {
  const _RightPanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _Friend extends StatelessWidget {
  const _Friend({
    required this.name,
    required this.status,
    required this.online,
  });

  final String name;
  final String status;
  final bool online;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(
                    name.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Mời', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
}

class _Rank extends StatelessWidget {
  const _Rank({
    required this.icon,
    required this.name,
    required this.points,
  });

  final String icon;
  final String name;
  final String points;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$points điểm',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

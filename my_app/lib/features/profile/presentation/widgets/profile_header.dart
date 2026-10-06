import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/profile_progress.dart';

const String _logoAsset = 'assets/images/logos/Logo1.png';
const String _bannerAsset = 'assets/images/banners/AnhSuoi.jpg';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    final level = (profile?['level'] as num?)?.toInt() ?? 1;
    final verified = profile?['is_verified'] == true;
    final progress = ProfileProgress.fromProfile(profile);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_bannerAsset, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD9202231)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      radius: 43,
                      fallbackAsset: _logoAsset,
                      avatarUrl: profile?['avatar_url'] as String?,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _value('display_name', fallback: 'Thợ săn mới'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '@${_value('username', fallback: 'chưa-cập-nhật')} · ${_value('city', fallback: 'TP. Hồ Chí Minh')}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  // Nhãn cấp bậc + Thanh tiến trình EXP được tích hợp ngay dưới tên
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D2C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: AppColors.cyan,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Thợ săn Cấp $level',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                if (verified) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.cyan,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${progress.exp} / ${progress.target} EXP',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress.fraction,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF292C3F),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      _value(
                        'bio',
                        fallback:
                            'Hãy thêm một vài dòng giới thiệu về bản thân và phong cách đi săn của bạn.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD2D9E6),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _value(String key, {required String fallback}) {
    final value = profile?[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}

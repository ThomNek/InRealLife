import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_navigation_shell.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'realtime_actions.dart';


class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.mobile,
    required this.profile,
  });

  final bool mobile;
  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (mobile) ...[
            const AppBrand(showText: false),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              readOnly: true,
              onTap: () {
                Navigator.pushNamed(context, '/users');
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Tìm bạn bè, thợ săn, mọi người...',
              ),
            ),
          ),
          const SizedBox(width: 10),
          const HomeRealtimeActions(),
          if (!mobile) ...[
            const SizedBox(width: 8),
            const _SquareButton(icon: Icons.settings_outlined),
          ],
          const SizedBox(width: 8),
          _AccountButton(profile: profile),
        ],
      );
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        onPressed: () {},
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.muted,
          fixedSize: const Size(48, 48),
        ),
      );
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}
    final isSignedIn = user != null;
    final profileName = profile?['display_name'] as String?;
    final metadataName = user?.userMetadata?['display_name'] as String?;
    final displayName = profileName?.trim().isNotEmpty == true
        ? profileName
        : metadataName;
    final profileAvatar = profile?['avatar_url'] as String?;
    final metadataAvatar = user?.userMetadata?['avatar_url'] as String?;
    final avatarUrl = profileAvatar?.trim().isNotEmpty == true
        ? profileAvatar
        : metadataAvatar;

    final profileGender = profile?['gender'] as String?;
    final metadataGender = user?.userMetadata?['gender'] as String?;
    final gender = profileGender?.trim().isNotEmpty == true
        ? profileGender
        : metadataGender;

    return Tooltip(
      message: isSignedIn ? 'Mở tài khoản' : 'Đăng nhập',
      child: PopupMenuButton<String>(
        tooltip: isSignedIn ? 'Tài khoản' : 'Đăng nhập',
        onSelected: (value) async {
          if (value == 'profile') {
            Navigator.pushNamed(context, '/profile');
          } else if (value == 'logout') {
            await _signOut(context);
          } else if (value == 'login') {
            Navigator.pushNamed(context, '/login');
          }
        },
        itemBuilder: (_) => isSignedIn
            ? [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(
                      displayName?.trim().isNotEmpty == true
                          ? displayName!
                          : 'Hồ sơ của tôi',
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Đăng xuất'),
                  ),
                ),
              ]
            : const [
                PopupMenuItem(
                  value: 'login',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.login_rounded),
                    title: Text('Đăng nhập'),
                  ),
                ),
              ],
        child: Material(
          color: AppColors.surface,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.orange, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: UserAvatar(
                avatarUrl: avatarUrl,
                gender: gender,
                radius: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } on AuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đăng xuất: ${error.message}')),
      );
    }
  }
}

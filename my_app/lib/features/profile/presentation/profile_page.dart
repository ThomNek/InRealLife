import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_navigation_shell.dart';
import '../data/profile_repository.dart';
import 'widgets/profile_content.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileRepository().fetchCurrentProfile();
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = ProfileRepository().fetchCurrentProfile();
    });
  }

  @override
  Widget build(BuildContext context) => MainShell(
        selectedIndex: 4,
        child: Scaffold(
          body: SafeArea(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ProfileLoadFailure(onRetry: _reloadProfile);
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 850;
                    return CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          backgroundColor: AppColors.background.withValues(
                            alpha: .94,
                          ),
                          leading: IconButton(
                            tooltip: 'Quay lại',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          title: const Text(
                            'Hồ sơ cá nhân',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          actions: [
                            IconButton(
                              tooltip: 'Chia sẻ hồ sơ',
                              onPressed: () => _showShareMessage(context),
                              icon: const Icon(Icons.ios_share_rounded),
                            ),
                            IconButton(
                              tooltip: 'Chỉnh sửa hồ sơ',
                              onPressed: () async {
                                final updated = await Navigator.pushNamed(
                                  context,
                                  '/profile/edit',
                                );
                                if (updated == true && mounted) _reloadProfile();
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 28 : 14,
                            14,
                            wide ? 28 : 14,
                            36,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1050),
                                child: Column(
                                  children: [
                                    ProfileHeader(profile: snapshot.data),
                                    const SizedBox(height: 16),
                                    ProfileInfo(profile: snapshot.data),
                                    const SizedBox(height: 16),
                                    ProfileStats(profile: snapshot.data),
                                    const SizedBox(height: 16),
                                    ProfileShowcase(profile: snapshot.data),
                                    const SizedBox(height: 16),
                                    const ProfileActivity(),
                                    const SizedBox(height: 16),
                                    _LogoutButton(
                                      onPressed: () async {
                                        await Supabase.instance.client.auth
                                            .signOut();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

  static void _showShareMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết hồ sơ mô phỏng.')),
    );
  }
}

class _ProfileLoadFailure extends StatelessWidget {
  const _ProfileLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.orange,
              ),
              const SizedBox(height: 14),
              const Text(
                'Không thể tải hồ sơ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              const Text(
                'Kiểm tra kết nối mạng rồi thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Đăng xuất'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent.shade100,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(
            color: Colors.redAccent.shade100.withValues(alpha: .4),
          ),
        ),
      );
}

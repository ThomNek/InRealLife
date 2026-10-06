import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

const String _logoAsset = 'assets/images/logos/Logo1.png';

const List<(String, IconData)> _navItems = [
  ('Trang chủ', Icons.home_rounded),
  ('Radar', Icons.radar_rounded),
  ('Hoạt động', Icons.event_available_rounded),
  ('Kho đồ', Icons.backpack_rounded),
  ('Hồ sơ', Icons.person_rounded),
];

const List<(String, IconData)> _sidebarItems = [
  ('Trang chủ', Icons.home_rounded),
  ('Bản đồ Radar', Icons.radar_rounded),
  ('Hoạt động', Icons.event_available_rounded),
  ('Kho Vật phẩm', Icons.backpack_rounded),
  ('Chợ Mảnh ghép', Icons.storefront_rounded),
];

/// Shared responsive navigation shell for all top-level main screens.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.selectedIndex,
    required this.child,
    this.floatingActionButton,
    this.showRightPanel = false,
    this.rightPanel,
  });

  final int selectedIndex;
  final Widget child;
  final Widget? floatingActionButton;
  final bool showRightPanel;
  final Widget? rightPanel;

  static void navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      case 1:
        Navigator.pushNamed(context, '/radar');
        return;
      case 2:
        Navigator.pushNamed(context, '/activities');
        return;
      case 3:
        Navigator.pushNamed(context, '/inventory');
        return;
      case 4:
        Navigator.pushNamed(context, '/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, size) {
          final desktop = size.maxWidth >= 1180;
          final tablet = size.maxWidth >= 760 && !desktop;

          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  desktop
                      ? 18
                      : tablet
                          ? 14
                          : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (desktop)
                      SizedBox(
                        width: 230,
                        child: AppSidebar(
                          selected: selectedIndex,
                          onSelected: (i) => navigateToTab(context, i),
                        ),
                      ),
                    if (tablet)
                      AppCompactRail(
                        selected: selectedIndex,
                        onSelected: (i) => navigateToTab(context, i),
                      ),
                    if (desktop || tablet) const SizedBox(width: 18),
                    Expanded(child: child),
                    if (desktop && showRightPanel && rightPanel != null) ...[
                      const SizedBox(width: 18),
                      SizedBox(width: 290, child: rightPanel!),
                    ],
                  ],
                ),
              ),
            ),
            bottomNavigationBar: desktop || tablet
                ? null
                : AppBottomBar(
                    selected: selectedIndex,
                    onSelected: (i) => navigateToTab(context, i),
                  ),
            floatingActionButton: floatingActionButton,
          );
        },
      );
}

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, required this.showText});

  final bool showText;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(_logoAsset, width: 42, height: 42, fit: BoxFit.cover),
          ),
          if (showText) ...[
            const SizedBox(width: 10),
            const Text(
              'TREASURE\nIRL',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1.05,
              ),
            ),
          ],
        ],
      );
}

class AppNavTile extends StatelessWidget {
  const AppNavTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? (active ? AppColors.cyan : AppColors.muted);
    return Material(
      color: active ? AppColors.cyan.withValues(alpha: .12) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 21, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    bool isSignedIn = false;
    try {
      isSignedIn = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      isSignedIn = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBrand(showText: true),
          const SizedBox(height: 22),
          for (var i = 0; i < _sidebarItems.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppNavTile(
                label: _sidebarItems[i].$1,
                icon: _sidebarItems[i].$2,
                active: selected == i,
                onTap: () {
                  if (i == 4) {
                    Navigator.pushNamed(context, '/market');
                  } else {
                    onSelected(i);
                  }
                },
              ),
            ),
          const SizedBox(height: 20),
          AppNavTile(
            label: isSignedIn ? 'Đăng xuất' : 'Đăng nhập',
            icon: isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
            color: Colors.redAccent.shade100,
            onTap: () async {
              try {
                if (isSignedIn) {
                  await Supabase.instance.client.auth.signOut();
                }
              } catch (_) {}
              if (context.mounted) {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

class AppCompactRail extends StatelessWidget {
  const AppCompactRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: NavigationRail(
          backgroundColor: Colors.transparent,
          minWidth: 72,
          selectedIndex: selected < _navItems.length ? selected : 0,
          onDestinationSelected: onSelected,
          labelType: NavigationRailLabelType.none,
          leading: const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: AppBrand(showText: false),
          ),
          indicatorColor: AppColors.cyan.withValues(alpha: .14),
          selectedIconTheme: const IconThemeData(color: AppColors.cyan),
          destinations: _navItems
              .map(
                (item) => NavigationRailDestination(
                  icon: Icon(item.$2),
                  label: Text(item.$1),
                ),
              )
              .toList(),
        ),
      );
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
        height: 70,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.orange.withValues(alpha: .16),
        selectedIndex: selected < _navItems.length ? selected : 0,
        onDestinationSelected: onSelected,
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.$2),
                selectedIcon: Icon(item.$2, color: AppColors.orange),
                label: item.$1,
              ),
            )
            .toList(),
      );
}

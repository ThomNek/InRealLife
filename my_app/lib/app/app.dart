import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/complete_profile_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/update_password_page.dart';
import '../features/activities/presentation/participation_page.dart';
import '../features/activities/presentation/activity_detail_page.dart';
import '../features/activities/presentation/solo_hunt_page.dart';
import '../features/activities/presentation/hunt_result_page.dart';
import '../features/activities/presentation/activity_review_page.dart';
import '../features/activities/presentation/create_activity_page.dart';
import '../features/activities/presentation/check_in_page.dart';
import '../features/inventory/presentation/inventory_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';
import '../features/posts/presentation/create_post_page.dart';
import '../features/radar/presentation/radar_page.dart';
import '../features/teams/presentation/create_team_page.dart';
import '../features/teams/presentation/team_detail_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/safety/presentation/safety_center_page.dart';
import '../features/chat/presentation/team_chat_page.dart';
import '../features/chat/presentation/conversation_page.dart';

class TreasureIrlApp extends StatefulWidget {
  const TreasureIrlApp({super.key});

  @override
  State<TreasureIrlApp> createState() => _TreasureIrlAppState();
}

class _TreasureIrlAppState extends State<TreasureIrlApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _activeUserId = auth.currentUser?.id;
    _authSubscription = auth.onAuthStateChange.listen(_handleAuthChange);
  }

  void _handleAuthChange(AuthState state) {
    final previousUserId = _activeUserId;
    final nextUserId = state.session?.user.id;
    _activeUserId = nextUserId;

    // Mọi thay đổi danh tính phải hủy các route đang giữ Future/Stream/State
    // của trạng thái trước. Đặc biệt null -> user qua email/deep link cần bỏ
    // route Đăng ký đang phủ AuthGate để màn onboarding/password recovery hiện.
    final signedIn = previousUserId == null && nextUserId != null;
    final signedOut = previousUserId != null && nextUserId == null;
    final switchedAccount =
        previousUserId != null &&
        nextUserId != null &&
        previousUserId != nextUserId;
    if (!signedIn && !signedOut && !switchedAccount) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    debugShowCheckedModeBanner: false,
    title: 'Treasure IRL',
    theme: AppTheme.dark,
    home: const AuthGate(),
    routes: {
      '/login': (context) => const LoginPage(),
      '/register': (context) => const RegisterPage(),
      '/forgot-password': (context) => const ForgotPasswordPage(),
      '/update-password': (context) => const UpdatePasswordPage(),
      '/complete-profile': (context) => const CompleteProfilePage(),
      '/profile': (context) => const _ProtectedRoute(child: ProfilePage()),
      '/profile/edit': (context) =>
          const _ProtectedRoute(child: EditProfilePage()),
      '/radar': (context) => const _ProtectedRoute(child: RadarPage()),
      '/inventory': (context) => const _ProtectedRoute(child: InventoryPage()),
      '/market': (context) =>
          const _ProtectedRoute(child: InventoryPage(initialTab: 2)),
      '/create-post': (context) =>
          const _ProtectedRoute(child: CreatePostPage()),
      '/activities': (context) =>
          const _ProtectedRoute(child: ParticipationPage()),
      '/activities/sunset': (context) =>
          const _ProtectedRoute(child: ActivityDetailPage()),
      '/solo-hunt': (context) => const _ProtectedRoute(child: SoloHuntPage()),
      // Giữ route cũ để các liên kết/bookmark trước đây vẫn hoạt động, nhưng
      // đưa về trang Hoạt động đã hợp nhất thay vì màn đội dữ liệu mẫu.
      '/teams': (context) => const _ProtectedRoute(child: ParticipationPage()),
      '/teams/create': (context) =>
          const _ProtectedRoute(child: CreateTeamPage()),
      '/activities/create': (context) =>
          const _ProtectedRoute(child: CreateActivityPage()),
      '/check-in': (context) => const _ProtectedRoute(child: CheckInPage()),
      '/teams/detail': (context) =>
          const _ProtectedRoute(child: TeamDetailPage()),
      '/teams/chat': (context) => const _ProtectedRoute(child: TeamChatPage()),
      '/chat': (context) => const _ProtectedRoute(child: ConversationPage()),
      '/hunt-result': (context) =>
          const _ProtectedRoute(child: HuntResultPage()),
      '/activity-review': (context) =>
          const _ProtectedRoute(child: ActivityReviewPage()),
      '/notifications': (context) =>
          const _ProtectedRoute(child: NotificationsPage()),
      '/safety': (context) => const _ProtectedRoute(child: SafetyCenterPage()),
    },
  );
}

/// Chặn deep link tới tính năng riêng tư trước khi dựng widget dữ liệu.
/// Đây là lớp điều hướng/UX; Supabase RLS vẫn là ranh giới bảo mật thật.
class _ProtectedRoute extends StatelessWidget {
  const _ProtectedRoute({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LoginPage();
    if (session.user.userMetadata?['onboarding_completed_at'] == null) {
      return const CompleteProfilePage();
    }
    return child;
  }
}

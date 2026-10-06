import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/presentation/home_page.dart';
import 'complete_profile_page.dart';
import 'login_page.dart';
import 'update_password_page.dart';

/// Chọn màn hình đầu tiên dựa trên phiên đăng nhập hiện tại.
///
/// AuthGate không quyết định quyền truy cập dữ liệu. Quyền vẫn được bảo vệ
/// bởi RLS/Functions ở Supabase; widget này chỉ điều khiển luồng giao diện.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const UpdatePasswordPage();
        }
        // currentSession bao gồm session đã được khôi phục từ local storage.
        // Dùng nó ngay lập tức để tránh chớp màn hình Login khi mở app.
        final session = client.auth.currentSession;

        if (session != null) {
          // Mỗi tài khoản có một key riêng. Khi đổi tài khoản, Flutter sẽ hủy
          // cây HomePage cũ (cùng toàn bộ State/Future của người cũ) rồi tạo lại.
          // Tên/avatar cũng nằm trong key để Home cập nhật ngay sau khi sửa hồ sơ.
          final metadata = session.user.userMetadata;
          final displayName = metadata?['display_name'] ?? '';
          final avatarUrl = metadata?['avatar_url'] ?? '';
          final onboardingCompleted =
              metadata?['onboarding_completed_at'] != null;
          if (!onboardingCompleted) {
            return KeyedSubtree(
              key: ValueKey('onboarding:${session.user.id}'),
              child: const CompleteProfilePage(),
            );
          }
          return KeyedSubtree(
            key: ValueKey('${session.user.id}:$displayName:$avatarUrl'),
            child: const HomePage(),
          );
        }

        // Chờ event đầu tiên trong trường hợp Supabase đang khôi phục session.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingPage();
        }

        return const LoginPage();
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

const _banner = 'assets/images/banners/AnhSuoi.jpg';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.4,
          colors: [Color(0xFF242637), AppColors.background],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 36 : 18),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(wide ? 28 : 22),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 50,
                              offset: Offset(0, 24),
                            ),
                          ],
                        ),
                        child: wide
                            ? Row(
                                children: [
                                  const Expanded(child: _LoginVisual()),
                                  Expanded(child: _buildForm()),
                                ],
                              )
                            : _buildForm(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: wide ? 30 : 12,
                  top: wide ? 24 : 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _buildForm() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TREASURE IRL',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 34),
          const Text(
            'Chào mừng trở lại',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng nhập để tiếp tục hoạt động và gặp lại những người đồng hành của bạn.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          const _FieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline_rounded),
              hintText: 'ban@example.com',
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Vui lòng nhập email';
              if (!email.contains('@')) return 'Email không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel('Mật khẩu'),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              hintText: 'Nhập mật khẩu',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.cyan,
              value: _rememberMe,
              onChanged: (value) =>
                  setState(() => _rememberMe = value ?? false),
              title: const Text(
                'Ghi nhớ đăng nhập',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Đăng nhập'),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'HOẶC',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: const Text('Google — sắp có'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chưa có tài khoản?',
                style: TextStyle(color: AppColors.muted),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Đăng ký ngay'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await _authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showError(_authMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Không thể đăng nhập. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (message.contains('email not confirmed')) {
      return 'Bạn cần xác nhận email trước khi đăng nhập.';
    }
    if (message.contains('too many requests')) {
      return 'Bạn thử quá nhiều lần. Vui lòng đợi một lúc.';
    }
    return error.message;
  }
}

class _LoginVisual extends StatelessWidget {
  const _LoginVisual();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 680,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_banner, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33181926), Color(0xF2181926)],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _AdventureBadge(),
              SizedBox(height: 18),
              Text(
                'Cùng bước ra ngoài\nvà tạo kết nối thật.',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Khám phá thành phố, tham gia hoạt động và kết nối qua những trải nghiệm chung.',
                style: TextStyle(
                  color: Color(0xFFD2D9E6),
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdventureBadge extends StatelessWidget {
  const _AdventureBadge();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.orange.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.orange.withValues(alpha: .5)),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Text(
        '●  CUỘC PHIÊU LƯU BẮT ĐẦU TẠI ĐÂY',
        style: TextStyle(
          color: Color(0xFFFFA15B),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
  );
}

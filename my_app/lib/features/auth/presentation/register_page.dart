import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

const _logo = 'assets/images/logos/Logo1.png';
const _banner = 'assets/images/banners/AnhSuoi.jpg';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _acceptedTerms = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.45,
          colors: [Color(0xFF292334), AppColors.background],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 36 : 18),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(child: _RegisterVisual()),
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
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 42),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipOval(child: Image.asset(_logo, width: 42, height: 42)),
              const SizedBox(width: 10),
              const Text(
                'TREASURE IRL',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Tạo tài khoản',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn hoạt động phù hợp và bắt đầu những kết nối ngoài đời thật.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Họ và tên'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded),
              hintText: 'Nguyễn Văn A',
            ),
            maxLength: 80,
            validator: (value) {
              final length = value?.trim().length ?? 0;
              if (length < 2) return 'Vui lòng nhập họ và tên';
              if (length > 80) return 'Họ và tên tối đa 80 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),
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
              if (!email.contains('@') || !email.contains('.')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              hintText: 'Ít nhất 8 ký tự',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => (value?.length ?? 0) < 8
                ? 'Mật khẩu cần ít nhất 8 ký tự'
                : null,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Xác nhận mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmationController,
            obscureText: _hideConfirmation,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.verified_user_outlined),
              hintText: 'Nhập lại mật khẩu',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _hideConfirmation = !_hideConfirmation),
                icon: Icon(
                  _hideConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => value != _passwordController.text
                ? 'Mật khẩu xác nhận không khớp'
                : null,
          ),
          const SizedBox(height: 10),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.cyan,
              value: _acceptedTerms,
              onChanged: (value) =>
                  setState(() => _acceptedTerms = value ?? false),
              title: const Text(
                'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                : const Text('Tạo tài khoản'),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Đã có tài khoản?',
                style: TextStyle(color: AppColors.muted),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đồng ý với điều khoản.')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final response = await _authRepository.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng ký thành công. Hãy mở email để xác nhận tài khoản.',
            ),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      // AuthGate đọc onboarding_completed_at và tự hiển thị đúng bước kế tiếp.
      // Quay về route gốc tránh xếp chồng hai CompleteProfilePage.
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showError(_authMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Không thể tạo tài khoản. Vui lòng thử lại.');
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
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'Email này đã được đăng ký.';
    }
    if (message.contains('password')) {
      return 'Mật khẩu chưa đáp ứng yêu cầu bảo mật.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Bạn thử quá nhiều lần. Vui lòng đợi một lúc.';
    }
    return error.message;
  }
}

class _RegisterVisual extends StatelessWidget {
  const _RegisterVisual();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 790,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_banner, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x22181926), Color(0xF2181926)],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(42),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.explore_rounded, color: AppColors.cyan, size: 38),
              SizedBox(height: 18),
              Text(
                'Kết nối tốt nhất\nbắt đầu từ cùng làm.',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Tạo hồ sơ, tham gia nhóm nhỏ và khám phá những hoạt động quanh thành phố.',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
  );
}

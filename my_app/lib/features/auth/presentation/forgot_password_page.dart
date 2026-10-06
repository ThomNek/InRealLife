import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _repository = AuthRepository();
  bool _sent = false;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _box(),
              child: _sent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 62,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Hãy kiểm tra email',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Nếu email tồn tại, chúng tôi đã gửi liên kết đặt lại mật khẩu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Quay lại đăng nhập'),
                        ),
                      ],
                    )
                  : Form(
                      key: _key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.lock_reset_rounded,
                            size: 58,
                            color: AppColors.orange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Quên mật khẩu?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (value) => !(value ?? '').contains('@')
                                ? 'Email không hợp lệ'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _sending ? null : _send,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Gửi liên kết'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _send() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await _repository.sendPasswordResetEmail(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi email: ${error.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi email. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

BoxDecoration _box() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: AppColors.border),
);

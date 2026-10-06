import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuestRealBootstrap());
}

/// Dựng giao diện ngay rồi mới khởi tạo Supabase để mạng chậm không tạo ra
/// một màn hình trắng không có phản hồi cho người dùng.
class QuestRealBootstrap extends StatefulWidget {
  const QuestRealBootstrap({super.key, this.initializer});

  /// Chỉ truyền trong test để kiểm tra các trạng thái loading/lỗi mà không
  /// khởi tạo thêm một Supabase singleton.
  final Future<void> Function()? initializer;

  @override
  State<QuestRealBootstrap> createState() => _QuestRealBootstrapState();
}

class _QuestRealBootstrapState extends State<QuestRealBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _startInitialization();
  }

  Future<void> _startInitialization() =>
      (widget.initializer ?? _initializeSupabase)();

  void _retry() {
    final nextInitialization = _startInitialization();
    setState(() {
      _initialization = nextInitialization;
    });
  }

  Future<void> _initializeSupabase() async {
    if (SupabaseConfig.url.isEmpty || SupabaseConfig.publishableKey.isEmpty) {
      throw Exception('Thiếu SUPABASE_URL hoặc SUPABASE_PUBLISHABLE_KEY');
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const TreasureIrlApp();
      }

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QuestReal',
        theme: AppTheme.dark,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: snapshot.hasError
                    ? _StartupError(error: snapshot.error, onRetry: _retry)
                    : const _StartupLoading(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 18),
      Text(
        'Đang kết nối QuestReal…',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.orangeAccent),
      const SizedBox(height: 16),
      const Text(
        'Không thể khởi động ứng dụng',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      const Text(
        'Hãy kiểm tra kết nối mạng rồi thử lại.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Thử kết nối lại'),
      ),
      if (kDebugMode) ...[
        const SizedBox(height: 14),
        SelectableText(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    ],
  );
}

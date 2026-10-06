import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HuntResultPage extends StatelessWidget {
  const HuntResultPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD22E).withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD22E),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Hoàn thành Kho báu Hoàng Hôn!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thành tích đã được xác minh mô phỏng.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _box(),
                  child: const Row(
                    children: [
                      Expanded(child: _Stat('32 phút', 'Thời gian')),
                      _Line(),
                      Expanded(child: _Stat('0', 'Gợi ý')),
                      _Line(),
                      Expanded(child: _Stat('+500', 'EXP')),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: _box(),
                  child: const Column(
                    children: [
                      Text(
                        'PHẦN THƯỞNG',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.extension_rounded,
                            color: Color(0xFFFFD22E),
                            size: 38,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mảnh ghép C2',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Đã thêm vào kho',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/activity-review',
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Đánh giá trải nghiệm'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (_) => false,
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Về trang chủ'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 38, color: AppColors.border);
}

BoxDecoration _box() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);

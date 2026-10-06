import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ActivityReviewPage extends StatefulWidget {
  const ActivityReviewPage({super.key});

  @override
  State<ActivityReviewPage> createState() => _ActivityReviewPageState();
}

class _ActivityReviewPageState extends State<ActivityReviewPage> {
  int _rating = 0;
  bool _safe = true;
  bool _again = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đánh giá hoạt động')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Trải nghiệm của bạn thế nào?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đánh giá chỉ mở sau hoạt động đã check-in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          index < _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFD22E),
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: _safe,
                    onChanged: (value) => setState(() => _safe = value),
                    title: const Text('Hoạt động và địa điểm an toàn'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _again,
                    onChanged: (value) => setState(() => _again = value),
                    title: const Text('Muốn tham gia hoạt động tương tự'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Góp ý riêng tư',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _rating == 0
                        ? null
                        : () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (_) => false,
                          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Gửi đánh giá'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/safety'),
                    child: const Text('Báo cáo vấn đề an toàn'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

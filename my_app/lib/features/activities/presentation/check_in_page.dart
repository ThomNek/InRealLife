import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});
  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  bool _located = false;
  bool _accepted = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Check-in an toàn',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: (_located ? Colors.greenAccent : AppColors.cyan)
                        .withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _located ? Icons.check_rounded : Icons.my_location_rounded,
                    size: 52,
                    color: _located ? Colors.greenAccent : AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _located
                      ? 'Đã ở trong khu vực hoạt động'
                      : 'Xác nhận bạn đã đến nơi',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cổng chính Công viên Trung tâm\nĐiểm hẹn công cộng đã được kiểm tra',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      _Rule('Dừng lại ở nơi an toàn trước khi xem điện thoại.'),
                      _Rule('Không đi vào khu vực riêng tư hoặc có biển cấm.'),
                      _Rule('Bạn có thể dừng hoạt động bất cứ lúc nào.'),
                    ],
                  ),
                ),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                  title: const Text('Tôi đồng ý tuân thủ hướng dẫn an toàn.'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: !_accepted
                      ? null
                      : () {
                          if (!_located) {
                            setState(() => _located = true);
                          } else {
                            Navigator.pushReplacementNamed(
                              context,
                              '/solo-hunt',
                            );
                          }
                        },
                  icon: Icon(
                    _located
                        ? Icons.play_arrow_rounded
                        : Icons.location_searching_rounded,
                  ),
                  label: Text(
                    _located ? 'Bắt đầu cuộc săn' : 'Xác nhận vị trí',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
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

class _Rule extends StatelessWidget {
  const _Rule(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.greenAccent,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

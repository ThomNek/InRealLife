import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SoloHuntPage extends StatefulWidget {
  const SoloHuntPage({super.key});
  @override
  State<SoloHuntPage> createState() => _SoloHuntPageState();
}

class _SoloHuntPageState extends State<SoloHuntPage> {
  final _answer = TextEditingController();
  int _step = 1;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Săn cá nhân',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _help(context),
          icon: const Icon(Icons.shield_outlined),
          label: const Text('An toàn'),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _step / 4,
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_step/4',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'MANH MỐI $_step',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Người đứng giữa thành phố, không bước đi nhưng luôn chỉ đường.',
                        style: TextStyle(
                          fontSize: 23,
                          height: 1.35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Hãy quan sát khu vực quanh tháp đồng hồ. Bạn không cần rời khỏi lối đi công cộng.',
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _answer,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Nhập đáp án',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _check,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Kiểm tra đáp án'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _hint(context),
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: const Text('Dùng một gợi ý'),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.directions_walk_rounded,
                          color: Colors.greenAccent,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hãy dừng lại ở nơi an toàn trước khi xem điện thoại. Không đi vào khu vực cấm hoặc riêng tư.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _check() {
    if (_answer.text.trim().isEmpty) {
      _message('Hãy nhập đáp án trước.');
      return;
    }
    if (_step < 4) {
      setState(() {
        _step++;
        _answer.clear();
      });
      _message('Chính xác! Đã mở manh mối tiếp theo.');
    } else {
      Navigator.pushReplacementNamed(context, '/hunt-result');
    }
  }

  void _hint(BuildContext context) =>
      _message('Gợi ý: vật này có kim nhưng không dùng để may.');
  void _help(BuildContext context) =>
      _message('Luôn ở nơi công cộng và chú ý giao thông xung quanh.');
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SafetyCenterPage extends StatelessWidget {
  const SafetyCenterPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Trung tâm an toàn',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.shield_rounded, size: 64, color: Colors.greenAccent),
          const SizedBox(height: 12),
          const Text(
            'An toàn trước mọi kết nối',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            'Chỉ gặp tại địa điểm công cộng và không công khai vị trí thời gian thực.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          const _Item(
            Icons.people_outline_rounded,
            'Gặp theo nhóm nhỏ',
            'Ưu tiên nhóm 3–6 người, có mục tiêu và người tổ chức rõ ràng.',
          ),
          const _Item(
            Icons.location_on_outlined,
            'Địa điểm công cộng',
            'Không dùng địa chỉ nhà hoặc khu vực hạn chế làm điểm hẹn.',
          ),
          const _Item(
            Icons.visibility_off_outlined,
            'Bảo vệ vị trí',
            'Chỉ chia sẻ điểm hẹn, không hiện GPS của thành viên.',
          ),
          const _Item(
            Icons.exit_to_app_rounded,
            'Bạn luôn có thể rời đi',
            'Rút khỏi hoạt động, chặn hoặc báo cáo bất kỳ lúc nào.',
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block_rounded),
            label: const Text('Người dùng đã chặn'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _report(context),
            icon: const Icon(Icons.report_outlined),
            label: const Text('Báo cáo sự cố'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    ),
  );
  static void _report(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        20,
        18,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Báo cáo sự cố',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Mô tả tình huống không an toàn...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Gửi báo cáo'),
          ),
        ],
      ),
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.cyan),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

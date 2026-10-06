import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/data/profile_repository.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});
  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  int _step = 0;
  final Set<String> _interests = {'Săn kho báu'};
  String _comfort = 'Nhóm nhỏ 3–4 người';
  double _distance = 5;
  bool _saving = false;
  static const _choices = [
    'Săn kho báu',
    'Đi bộ',
    'Chạy bộ',
    'Cầu lông',
    'Cà phê',
    'Board game',
    'Chụp ảnh',
    'Giải đố',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thiết lập trải nghiệm'),
      automaticallyImplyLeading: false,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _content(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          child: const Text('Quay lại'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _next,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_step == 2 ? 'Hoàn tất' : 'Tiếp tục'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _content() => switch (_step) {
    0 => Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn muốn làm gì ngoài đời?',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        const Text(
          'Chọn những hoạt động bạn thực sự muốn tham gia.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _choices
              .map(
                (item) => FilterChip(
                  selected: _interests.contains(item),
                  label: Text(item),
                  onSelected: (value) => setState(
                    () =>
                        value ? _interests.add(item) : _interests.remove(item),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
    1 => Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn thoải mái gặp gỡ thế nào?',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children:
              ['Chỉ hoạt động cá nhân', 'Nhóm nhỏ 3–4 người', 'Nhóm 5–8 người']
                  .map(
                    (option) => ChoiceChip(
                      selected: _comfort == option,
                      showCheckmark: false,
                      label: Text(option),
                      onSelected: (_) => setState(() => _comfort = option),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Khoảng cách sẵn sàng di chuyển',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        Slider(
          value: _distance,
          min: 1,
          max: 20,
          divisions: 19,
          label: '${_distance.round()} km',
          onChanged: (value) => setState(() => _distance = value),
        ),
        Center(
          child: Text(
            '${_distance.round()} km',
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
    _ => const Column(
      key: ValueKey(2),
      children: [
        Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 64),
        SizedBox(height: 18),
        Text(
          'An toàn trước khi kết nối',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 12),
        _SafetyLine('Chỉ gặp tại địa điểm công cộng.'),
        _SafetyLine('Không chia sẻ địa chỉ nhà hoặc vị trí trực tiếp.'),
        _SafetyLine('Bạn có thể rời, chặn hoặc báo cáo bất kỳ lúc nào.'),
        _SafetyLine('Hãy chú ý môi trường xung quanh khi di chuyển.'),
      ],
    ),
  };

  Future<void> _next() async {
    if (_step == 0 && _interests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ít nhất một sở thích.')),
      );
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      setState(() => _saving = true);
      try {
        await ProfileRepository().completeOnboarding(
          interests: _interests.toList(),
          comfortPreference: _comfort,
          travelRadiusKm: _distance.round(),
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu thiết lập: $error')),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }
}

class _SafetyLine extends StatelessWidget {
  const _SafetyLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.cyan, size: 20),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

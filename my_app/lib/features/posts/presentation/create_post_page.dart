import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

const _logo = 'assets/images/logos/Logo1.png';

enum _PostType { teammate, clue, trade, achievement }

Future<void> showCreatePostComposer(BuildContext context) {
  final desktop = MediaQuery.sizeOf(context).width >= 700;
  if (desktop) {
    return showDialog<void>(
      context: context,
      builder: (_) => const Dialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.background,
        child: SizedBox(width: 700, height: 760, child: CreatePostPage()),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: .94, child: CreatePostPage()),
  );
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  _PostType _type = _PostType.teammate;
  String _visibility = 'Công khai';
  String? _location;
  bool _hasImage = false;
  bool _posting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Đóng',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
      title: const Text(
        'Tạo bài đăng',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        TextButton(
          onPressed: _posting ? null : _submit,
          child: const Text(
            'Đăng',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _AuthorCard(),
                      const SizedBox(height: 16),
                      _PostTypePicker(
                        selected: _type,
                        onSelected: (value) => setState(() => _type = value),
                      ),
                      const SizedBox(height: 16),
                      _Composer(
                        controller: _contentController,
                        type: _type,
                        hasImage: _hasImage,
                        onRemoveImage: () => setState(() => _hasImage = false),
                      ),
                      const SizedBox(height: 16),
                      _OptionsCard(
                        location: _location,
                        visibility: _visibility,
                        onLocationChanged: (value) =>
                            setState(() => _location = value),
                        onVisibilityChanged: (value) =>
                            setState(() => _visibility = value),
                        onAddImage: () => setState(() => _hasImage = true),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _posting ? null : _submit,
                        icon: _posting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_posting ? 'Đang đăng...' : 'Đăng bài'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Hãy tôn trọng cộng đồng và không công khai đáp án manh mối.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _posting = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Đã đăng bài lên cộng đồng.')),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _decoration(),
    child: const Row(
      children: [
        CircleAvatar(radius: 24, backgroundImage: AssetImage(_logo)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thom Nguyen',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'Thợ săn cấp 1',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(Icons.verified_rounded, color: AppColors.cyan, size: 20),
      ],
    ),
  );
}

class _PostTypePicker extends StatelessWidget {
  const _PostTypePicker({required this.selected, required this.onSelected});
  final _PostType selected;
  final ValueChanged<_PostType> onSelected;

  static const _items = [
    (
      _PostType.teammate,
      'Tìm đồng đội',
      Icons.group_add_outlined,
      AppColors.cyan,
    ),
    (
      _PostType.clue,
      'Chia sẻ manh mối',
      Icons.search_rounded,
      Color(0xFFB567F3),
    ),
    (
      _PostType.trade,
      'Đổi mảnh ghép',
      Icons.extension_rounded,
      Color(0xFF65D96E),
    ),
    (
      _PostType.achievement,
      'Thành tích',
      Icons.emoji_events_outlined,
      Color(0xFFFFC928),
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BẠN MUỐN ĐĂNG GÌ?', style: _sectionTitle),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _items.map((item) {
            final active = selected == item.$1;
            return ChoiceChip(
              selected: active,
              onSelected: (_) => onSelected(item.$1),
              avatar: Icon(
                item.$3,
                size: 18,
                color: active ? item.$4 : AppColors.muted,
              ),
              label: Text(item.$2),
              selectedColor: item.$4.withValues(alpha: .15),
              side: BorderSide(color: active ? item.$4 : AppColors.border),
              labelStyle: TextStyle(
                color: active ? item.$4 : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.type,
    required this.hasImage,
    required this.onRemoveImage,
  });
  final TextEditingController controller;
  final _PostType type;
  final bool hasImage;
  final VoidCallback onRemoveImage;

  String get hint => switch (type) {
    _PostType.teammate => 'Bạn đang cần đồng đội cho cuộc săn nào?',
    _PostType.clue => 'Chia sẻ gợi ý nhưng đừng tiết lộ đáp án nhé...',
    _PostType.trade => 'Bạn có mảnh nào và đang cần tìm mảnh nào?',
    _PostType.achievement => 'Chia sẻ thành tích mới của bạn...',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _decoration(),
    child: Column(
      children: [
        TextFormField(
          controller: controller,
          minLines: 6,
          maxLines: 10,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Hãy nhập nội dung bài viết';
            if (text.length < 10) return 'Nội dung cần ít nhất 10 ký tự';
            return null;
          },
        ),
        if (hasImage) ...[
          const Divider(),
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, color: AppColors.cyan, size: 38),
                    SizedBox(height: 6),
                    Text(
                      'Ảnh sẽ hiển thị tại đây',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 7,
                top: 7,
                child: IconButton.filled(
                  tooltip: 'Xóa ảnh',
                  onPressed: onRemoveImage,
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xCC151722),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.location,
    required this.visibility,
    required this.onLocationChanged,
    required this.onVisibilityChanged,
    required this.onAddImage,
  });
  final String? location;
  final String visibility;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<String> onVisibilityChanged;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('THÊM VÀO BÀI VIẾT', style: _sectionTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onAddImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Ảnh'),
            ),
            OutlinedButton.icon(
              onPressed: () => onLocationChanged(
                location == null ? 'Công viên Trung tâm' : null,
              ),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(location ?? 'Vị trí'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.extension_outlined),
              label: const Text('Mảnh ghép'),
            ),
          ],
        ),
        const Divider(height: 26),
        Row(
          children: [
            const Icon(Icons.visibility_outlined, color: AppColors.muted),
            const SizedBox(width: 10),
            const Expanded(child: Text('Ai có thể xem bài viết?')),
            DropdownButton<String>(
              value: visibility,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'Công khai', child: Text('Công khai')),
                DropdownMenuItem(value: 'Bạn bè', child: Text('Bạn bè')),
                DropdownMenuItem(value: 'Đội săn', child: Text('Đội săn')),
              ],
              onChanged: (value) {
                if (value != null) onVisibilityChanged(value);
              },
            ),
          ],
        ),
      ],
    ),
  );
}

const _sectionTitle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
  fontSize: 12,
  letterSpacing: .7,
);

BoxDecoration _decoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);

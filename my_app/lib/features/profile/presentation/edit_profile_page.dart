import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_repository.dart';

const _logo = 'assets/images/logos/Logo1.png';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileRepository = ProfileRepository();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _avatarUrl = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _birthYear = TextEditingController();
  String _visibility = 'public';
  bool _loading = true;
  Object? _loadError;
  bool _saving = false;
  final Set<String> _interests = {};

  static const _interestOptions = [
    ('🧭', 'Khám phá'),
    ('🧩', 'Giải đố'),
    ('🤝', 'Kết bạn'),
    ('🏃', 'Vận động'),
    ('📷', 'Chụp ảnh'),
    ('🌿', 'Thiên nhiên'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final profile = await _profileRepository.fetchCurrentProfile();
      if (!mounted) return;
      if (profile == null) {
        final user = Supabase.instance.client.auth.currentUser;
        final metadata = user?.userMetadata;
        _name.text =
            (metadata?['display_name'] as String?)?.trim().isNotEmpty == true
            ? (metadata!['display_name'] as String).trim()
            : (user?.email?.split('@').first ?? 'Người dùng');
      } else {
        _name.text = (profile['display_name'] as String?) ?? '';
        _username.text = (profile['username'] as String?) ?? '';
        _avatarUrl.text = (profile['avatar_url'] as String?) ?? '';
        _bio.text = (profile['bio'] as String?) ?? '';
        _city.text = (profile['city'] as String?) ?? '';
        _birthYear.text =
            (profile['birth_year'] as num?)?.toInt().toString() ?? '';
        _visibility = (profile['profile_visibility'] as String?) ?? 'public';
        final interests = profile['interests'];
        _interests
          ..clear()
          ..addAll(
            interests is List ? interests.whereType<String>() : const [],
          );
      }
    } catch (error) {
      if (mounted) _loadError = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _avatarUrl.dispose();
    _bio.dispose();
    _city.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Chỉnh sửa hồ sơ',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: const Text(
            'Lưu',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _ProfileLoadError(onRetry: _loadProfile)
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 800;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 28 : 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _AvatarEditor(
                              avatarUrl: _avatarUrl.text,
                              onTap: () => _message(
                                'Chức năng chọn ảnh sẽ kết nối sau.',
                              ),
                            ),
                            const SizedBox(height: 18),
                            _EditSection(
                              number: '1',
                              title: 'Thông tin cơ bản',
                              subtitle: 'Tên và username xuất hiện ở mọi nơi trong cộng đồng.',
                              child: Column(
                                children: [
                                  _ResponsiveFields(
                                    wide: wide,
                                    children: [
                                      _ProfileField(
                                        label: 'Tên hiển thị *',
                                        controller: _name,
                                        icon: Icons.person_outline_rounded,
                                        maxLength: 80,
                                        validator: (value) {
                                          final length =
                                              value?.trim().length ?? 0;
                                          if (length < 2) {
                                            return 'Vui lòng nhập tên hiển thị';
                                          }
                                          if (length > 80) {
                                            return 'Tên tối đa 80 ký tự';
                                          }
                                          return null;
                                        },
                                      ),
                                      _ProfileField(
                                        label: 'Username',
                                        controller: _username,
                                        icon: Icons.alternate_email_rounded,
                                        maxLength: 30,
                                        validator: _validateUsername,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _ProfileField(
                                    label: 'URL ảnh đại diện',
                                    controller: _avatarUrl,
                                    icon: Icons.link_rounded,
                                    hint: 'https://...',
                                    keyboardType: TextInputType.url,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 14),
                                  _ProfileField(
                                    label: 'Giới thiệu',
                                    controller: _bio,
                                    icon: Icons.notes_rounded,
                                    maxLines: 4,
                                    maxLength: 500,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _EditSection(
                              number: '2',
                              title: 'Thông tin thêm',
                              subtitle: 'Địa điểm và năm sinh giúp kết nối với thợ săn gần bạn.',
                              child: Column(
                                children: [
                                  _ResponsiveFields(
                                    wide: wide,
                                    children: [
                                      _ProfileField(
                                        label: 'Địa điểm',
                                        controller: _city,
                                        icon: Icons.location_on_outlined,
                                        maxLength: 120,
                                      ),
                                      _ProfileField(
                                        label: 'Năm sinh',
                                        controller: _birthYear,
                                        icon: Icons.cake_outlined,
                                        hint: 'Ví dụ: 1995',
                                        keyboardType: TextInputType.number,
                                        validator: _validateBirthYear,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    initialValue: _visibility,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Quyền riêng tư hồ sơ',
                                      prefixIcon: Icon(
                                        Icons.visibility_outlined,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'public',
                                        child: Text(
                                          'Công khai — Mọi người đều có thể xem',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'shared',
                                        child: Text(
                                          'Cùng đội — Chỉ người có hoạt động chung',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'private',
                                        child: Text(
                                          'Riêng tư — Chỉ mình bạn xem được',
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _visibility = value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _EditSection(
                              number: '3',
                              title: 'Sở thích',
                              subtitle: 'Chọn sở thích để hiển thị trên hồ sơ của bạn.',
                              child: Wrap(
                                spacing: 9,
                                runSpacing: 9,
                                children: _interestOptions.map((item) {
                                  final selected = _interests.contains(item.$2);
                                  return FilterChip(
                                    selected: selected,
                                    showCheckmark: false,
                                    label: Text('${item.$1} ${item.$2}'),
                                    selectedColor: AppColors.cyan.withValues(
                                      alpha: .15,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.cyan
                                          : AppColors.border,
                                    ),
                                    onSelected: (value) => setState(() {
                                      value
                                          ? _interests.add(item.$2)
                                          : _interests.remove(item.$2);
                                    }),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                    ),
                                    child: const Text('Hủy'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _saving ? null : _save,
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: Text(
                                      _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                    ),
                                  ),
                                ),
                              ],
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

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return null;
    if (username.length < 3) return 'Username cần ít nhất 3 ký tự';
    if (username.length > 30) return 'Username tối đa 30 ký tự';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return 'Chỉ dùng chữ thường, số hoặc dấu gạch dưới';
    }
    return null;
  }

  String? _validateBirthYear(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final year = int.tryParse(value);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Năm sinh không hợp lệ';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _profileRepository.updateCurrentProfile(
        displayName: _name.text,
        username: _username.text,
        avatarUrl: _avatarUrl.text,
        bio: _bio.text,
        city: _city.text,
        interests: _interests.toList(),
        birthYear: int.tryParse(_birthYear.text.trim()),
        profileVisibility: _visibility,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (mounted) _message(error.message);
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Không thể lưu hồ sơ. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.avatarUrl, required this.onTap});
  final String avatarUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl.trim().isEmpty
                  ? const AssetImage(_logo)
                  : NetworkImage(avatarUrl.trim()),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              tooltip: 'Đổi ảnh đại diện',
              onPressed: onTap,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.background,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Thay đổi ảnh đại diện',
        style: TextStyle(color: AppColors.muted),
      ),
    ],
  );
}

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String number;
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.wide, required this.children});
  final bool wide;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => wide
      ? Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 14),
            Expanded(child: children[1]),
          ],
        )
      : Column(
          children: [children[0], const SizedBox(height: 14), children[1]],
        );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    maxLength: maxLength,
    validator: validator,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      alignLabelWithHint: maxLines > 1,
    ),
  );
}

BoxDecoration _decoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppColors.orange,
          ),
          const SizedBox(height: 14),
          const Text(
            'Không thể tải hồ sơ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            'Kiểm tra kết nối rồi thử lại. Dữ liệu hiện tại chưa bị thay đổi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

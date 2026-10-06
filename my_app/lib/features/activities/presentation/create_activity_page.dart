import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/activity_repository.dart';
import 'widgets/create_activity_group_section.dart';
import 'widgets/create_activity_schedule_section.dart';
import 'widgets/create_activity_type_section.dart';

/// Trang Tạo hoạt động (Modular UI Component)
class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _preparation = TextEditingController();
  final _repository = ActivityRepository();

  String _type = 'Săn kho báu';
  String _level = 'Mọi trình độ';
  int _people = 4;
  String _targetGender = 'all'; // all, female_only, male_only
  String _joinPolicy = 'everyone'; // everyone, friends_only
  DateTime _startsAt = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  // Danh sách kho báu cá nhân do hệ thống tự sinh cho tài khoản
  final List<Map<String, String>> _personalTreasures = [
    {
      'id': 'TR-01',
      'name': '💎 Rương Cổ Thụ (Công viên Q.1)',
      'location': 'Công viên Tao Đàn, Quận 1, TP.HCM',
      'distance': '0.8 km',
    },
    {
      'id': 'TR-02',
      'name': '💎 Rương Hoàng Hôn (Bờ sông Sài Gòn)',
      'location': 'Công viên Bến Bạch Đằng, Quận 1',
      'distance': '1.5 km',
    },
    {
      'id': 'TR-03',
      'name': '💎 Rương Thư Viện (Thần thoại)',
      'location': 'Thư viện KHKT, Quận 3, TP.HCM',
      'distance': '2.1 km',
    },
  ];

  int _selectedTreasureIndex = 0;

  bool get _isTreasureHunt => _type == 'Săn kho báu';

  @override
  void initState() {
    super.initState();
    _updateAutoFields();
  }

  void _updateAutoFields() {
    if (_isTreasureHunt) {
      final selected = _personalTreasures[_selectedTreasureIndex];
      _title.text = 'Săn ${selected['name']}';
      _location.text = selected['location']!;
    } else {
      _title.text = _type;
      if (_location.text == 'Công viên Tao Đàn, Quận 1, TP.HCM' ||
          _location.text == 'Công viên Bến Bạch Đằng, Quận 1' ||
          _location.text == 'Thư viện KHKT, Quận 3, TP.HCM') {
        _location.clear();
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _preparation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tạo hoạt động',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tạo một lý do để gặp nhau',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hoạt động cần có mục tiêu rõ, địa điểm công cộng và số người phù hợp.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),

                      // Section 1: Loại hoạt động
                      CreateActivityTypeSection(
                        selectedType: _type,
                        isTreasureHunt: _isTreasureHunt,
                        personalTreasures: _personalTreasures,
                        selectedTreasureIndex: _selectedTreasureIndex,
                        titleController: _title,
                        descriptionController: _description,
                        onTypeChanged: (value) {
                          setState(() {
                            _type = value;
                            _updateAutoFields();
                          });
                        },
                        onTreasureChanged: (index) {
                          setState(() {
                            _selectedTreasureIndex = index;
                            _updateAutoFields();
                          });
                        },
                        validatorWithLimit: _requiredWithLimit,
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Thời gian & Địa điểm
                      CreateActivityScheduleSection(
                        startsAt: _startsAt,
                        isTreasureHunt: _isTreasureHunt,
                        locationController: _location,
                        onPickStartsAt: _pickStartsAt,
                        validatorWithLimit: _requiredWithLimit,
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Nhóm tham gia, Đối tượng giới tính & Quyền gia nhập
                      CreateActivityGroupSection(
                        level: _level,
                        people: _people,
                        targetGender: _targetGender,
                        joinPolicy: _joinPolicy,
                        preparationController: _preparation,
                        onLevelChanged: (val) => setState(() => _level = val),
                        onPeopleDecrement: () => setState(() => _people--),
                        onPeopleIncrement: () => setState(() => _people++),
                        onGenderChanged: (val) =>
                            setState(() => _targetGender = val),
                        onPolicyChanged: (val) =>
                            setState(() => _joinPolicy = val),
                      ),
                      const SizedBox(height: 18),

                      FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: const Icon(Icons.publish_rounded),
                        label: Text(_saving ? 'Đang tạo...' : 'Đăng hoạt động'),
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
        ),
      );

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Thông tin này là bắt buộc' : null;

  String? _requiredWithLimit(
    String? value, {
    required int maxLength,
    required String label,
  }) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (value!.trim().length > maxLength) {
      return '$label tối đa $maxLength ký tự';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.createActivity(
        title: _title.text,
        description: _description.text,
        type: _activityTypeValue(_type),
        locationName: _location.text,
        maxMembers: _people,
        startsAt: _startsAt,
        skillLevel: _activityLevelValue(_level),
        preparationNotes: _preparation.text,
        targetGender: _targetGender,
        joinPolicy: _joinPolicy,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo hoạt động: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _activityTypeValue(String value) {
    switch (value) {
      case 'Săn kho báu':
        return 'treasure_hunt';
      case 'Đi bộ':
        return 'walking';
      case 'Chạy bộ':
        return 'walking';
      case 'Cầu lông':
        return 'sport';
      case 'Cà phê câu đố':
        return 'coffee';
      case 'Board game':
        return 'board_game';
      default:
        return 'other';
    }
  }

  String _activityLevelValue(String value) => switch (value) {
        'Mới bắt đầu' => 'beginner',
        'Cơ bản' => 'basic',
        'Trung bình' => 'intermediate',
        'Nâng cao' => 'advanced',
        _ => 'all',
      };

  Future<void> _pickStartsAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (selected.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian phải ở trong tương lai.')),
      );
      return;
    }
    setState(() => _startsAt = selected);
  }
}

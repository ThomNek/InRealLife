import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/team_repository.dart';

class CreateTeamPage extends StatefulWidget {
  const CreateTeamPage({super.key});

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _area = TextEditingController();
  final _repository = TeamRepository();
  int _maxMembers = 4;
  String _skillLevel = 'beginner';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Tạo đội săn',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tạo một nhóm để cùng tham gia hoạt động ngoài đời.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _name,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Tên đội *',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      if (length < 2) return 'Nhập tên đội';
                      if (length > 80) return 'Tên đội tối đa 80 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả đội',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _area,
                    maxLength: 160,
                    decoration: const InputDecoration(
                      labelText: 'Khu vực/điểm hẹn chung',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _skillLevel,
                    decoration: const InputDecoration(labelText: 'Trình độ'),
                    items: const [
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Text('Mới bắt đầu'),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Text('Trung bình'),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Text('Nâng cao'),
                      ),
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Mọi trình độ'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _skillLevel = value ?? 'beginner'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _maxMembers,
                    decoration: const InputDecoration(
                      labelText: 'Số thành viên tối đa',
                    ),
                    items: [
                      for (var i = 2; i <= 12; i++)
                        DropdownMenuItem(value: i, child: Text('$i người')),
                    ],
                    onChanged: (value) =>
                        setState(() => _maxMembers = value ?? 4),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(_saving ? 'Đang tạo...' : 'Tạo đội'),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.createTeam(
        name: _name.text,
        description: _description.text,
        maxMembers: _maxMembers,
        skillLevel: _skillLevel,
        meetingArea: _area.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể tạo đội: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

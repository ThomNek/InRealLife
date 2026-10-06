import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Section 3: Nhóm tham gia, Đối tượng giới tính & Quyền gia nhập
class CreateActivityGroupSection extends StatelessWidget {
  const CreateActivityGroupSection({
    super.key,
    required this.level,
    required this.people,
    required this.targetGender,
    required this.joinPolicy,
    required this.preparationController,
    required this.onLevelChanged,
    required this.onPeopleDecrement,
    required this.onPeopleIncrement,
    required this.onGenderChanged,
    required this.onPolicyChanged,
  });

  final String level;
  final int people;
  final String targetGender;
  final String joinPolicy;
  final TextEditingController preparationController;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onPeopleDecrement;
  final VoidCallback onPeopleIncrement;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onPolicyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. Nhóm tham gia & Quyền gia nhập',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),

          // 1. Trình độ yêu cầu
          DropdownButtonFormField<String>(
            initialValue: level,
            decoration: const InputDecoration(
              labelText: 'Trình độ yêu cầu',
              prefixIcon: Icon(Icons.signal_cellular_alt_rounded),
            ),
            items: const [
              'Mọi trình độ',
              'Mới bắt đầu',
              'Cơ bản',
              'Trung bình',
              'Nâng cao',
            ]
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onLevelChanged(value);
            },
          ),
          const SizedBox(height: 13),

          // 2. Số người tối đa
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số người tối đa trong đội',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: people > 2 ? onPeopleDecrement : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$people',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.cyan,
                ),
              ),
              IconButton(
                onPressed: people < 12 ? onPeopleIncrement : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // 3. Giới tính tham gia (Target gender)
          DropdownButtonFormField<String>(
            initialValue: targetGender,
            decoration: const InputDecoration(
              labelText: 'Giới tính tham gia',
              prefixIcon: Icon(Icons.wc_rounded),
            ),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('👥 Nam & Nữ (Tất cả)'),
              ),
              DropdownMenuItem(
                value: 'female_only',
                child: Text('👩 Chỉ nữ (Female only)'),
              ),
              DropdownMenuItem(
                value: 'male_only',
                child: Text('👨 Chỉ nam (Male only)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onGenderChanged(value);
            },
          ),
          const SizedBox(height: 13),

          // 4. Ai có thể tham gia (Join policy)
          DropdownButtonFormField<String>(
            initialValue: joinPolicy,
            decoration: const InputDecoration(
              labelText: 'Ai có thể tham gia (Quyền gia nhập)',
              prefixIcon: Icon(Icons.lock_person_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'everyone',
                child: Text('🌐 Mọi người (Công khai)'),
              ),
              DropdownMenuItem(
                value: 'friends_only',
                child: Text('🤝 Chỉ bạn bè (Trong danh sách bạn bè)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onPolicyChanged(value);
            },
          ),
          const SizedBox(height: 13),

          // 5. Vật dụng chuẩn bị & quy tắc
          TextField(
            controller: preparationController,
            maxLines: 2,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Vật dụng chuẩn bị & Quy tắc đội',
              hintText: 'VD: Nước uống, giày thể thao, đúng giờ...',
            ),
          ),
        ],
      ),
    );
  }
}

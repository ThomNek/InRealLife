import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'treasure_map_preview.dart';

/// Section 1: Chọn loại hoạt động & Mô tả
class CreateActivityTypeSection extends StatelessWidget {
  const CreateActivityTypeSection({
    super.key,
    required this.selectedType,
    required this.isTreasureHunt,
    required this.personalTreasures,
    required this.selectedTreasureIndex,
    required this.titleController,
    required this.descriptionController,
    required this.onTypeChanged,
    required this.onTreasureChanged,
    required this.validatorWithLimit,
  });

  final String selectedType;
  final bool isTreasureHunt;
  final List<Map<String, String>> personalTreasures;
  final int selectedTreasureIndex;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onTreasureChanged;
  final String? Function(String?, {required int maxLength, required String label}) validatorWithLimit;

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
            '1. Loại hoạt động',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              labelText: 'Chọn loại hoạt động',
            ),
            items: const [
              'Săn kho báu',
              'Đi bộ',
              'Chạy bộ',
              'Cầu lông',
              'Cà phê câu đố',
              'Board game',
            ]
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: 10),

          // ẨN / HIỆN FORM TỰ ĐỘNG THEO LOẠI HOẠT ĐỘNG
          if (isTreasureHunt) ...[
            const Text(
              'Chọn kho báu cá nhân để tạo đội đi săn:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: selectedTreasureIndex,
              decoration: const InputDecoration(
                labelText: 'Kho báu xuất hiện của bạn',
                prefixIcon: Icon(
                  Icons.diamond_outlined,
                  color: Color(0xFFFFD428),
                ),
              ),
              items: List.generate(
                personalTreasures.length,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text(
                    personalTreasures[index]['name']!,
                  ),
                ),
              ),
              onChanged: (index) {
                if (index != null) onTreasureChanged(index);
              },
            ),
            const SizedBox(height: 12),
            TreasureMapPreview(
              treasureName: personalTreasures[selectedTreasureIndex]['name']!,
              location: personalTreasures[selectedTreasureIndex]['location']!,
              distance: personalTreasures[selectedTreasureIndex]['distance']!,
            ),
          ] else ...[
            TextFormField(
              controller: titleController,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Tên hoạt động *',
                hintText: 'VD: Đi bộ rèn luyện sức khỏe cuối tuần',
              ),
              validator: (value) => validatorWithLimit(
                value,
                maxLength: 120,
                label: 'Tên hoạt động',
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: isTreasureHunt
                  ? 'Mô tả & Ghi chú cho đồng đội'
                  : 'Mô tả và mục tiêu hoạt động',
              hintText: isTreasureHunt
                  ? 'VD: Cần 2 bạn giữ mảnh ghép B7 để cùng giải câu đố...'
                  : 'Mô tả chi tiết mục tiêu...',
              alignLabelWithHint: true,
            ),
            validator: (value) => validatorWithLimit(
              value,
              maxLength: 2000,
              label: 'Mô tả',
            ),
          ),
        ],
      ),
    );
  }
}

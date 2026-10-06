import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Section 2: Thời gian và Địa điểm
class CreateActivityScheduleSection extends StatelessWidget {
  const CreateActivityScheduleSection({
    super.key,
    required this.startsAt,
    required this.isTreasureHunt,
    required this.locationController,
    required this.onPickStartsAt,
    required this.validatorWithLimit,
  });

  final DateTime startsAt;
  final bool isTreasureHunt;
  final TextEditingController locationController;
  final VoidCallback onPickStartsAt;
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
            '2. Thời gian và địa điểm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPickStartsAt,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Ngày và giờ tập hợp',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                suffixIcon: Icon(Icons.edit_calendar_rounded),
              ),
              child: Text(_formatDateTime(startsAt)),
            ),
          ),
          const SizedBox(height: 13),
          if (!isTreasureHunt)
            TextFormField(
              controller: locationController,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Địa điểm công cộng *',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) => validatorWithLimit(
                value,
                maxLength: 160,
                label: 'Địa điểm',
              ),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tọa độ kho báu (Hệ thống tự gán)',
                prefixIcon: Icon(Icons.my_location_rounded),
              ),
              child: Text(
                locationController.text,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Colors.greenAccent,
                size: 18,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Không sử dụng địa chỉ nhà hoặc khu vực riêng tư.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} · ${two(value.hour)}:${two(value.minute)}';
  }
}

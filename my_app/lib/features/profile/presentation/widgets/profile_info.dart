import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileInfo extends StatelessWidget {
  const ProfileInfo({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    final showAge = profile?['show_age'] != false;
    final showLocation = profile?['show_location'] != false;
    final birthDate = profile?['birth_date'] as String?;
    final birthYear = (profile?['birth_year'] as num?)?.toInt();
    final city = (profile?['city'] as String?)?.trim();
    final district = (profile?['district'] as String?)?.trim();
    final education = (profile?['education'] as String?)?.trim();
    final gender = (profile?['gender'] as String?)?.trim();

    // Tính toán hiển thị Nơi ở
    String locationText = 'Chưa cập nhật nơi ở';
    if (city?.isNotEmpty == true || district?.isNotEmpty == true) {
      final parts = [if (district?.isNotEmpty == true) district, if (city?.isNotEmpty == true) city];
      locationText = parts.join(', ');
    }

    // Tính toán hiển thị Ngày sinh / Tuổi
    String ageText = 'Chưa cập nhật ngày sinh';
    if (birthDate?.isNotEmpty == true) {
      ageText = birthDate!;
    } else if (birthYear != null) {
      final currentYear = DateTime.now().year;
      final age = currentYear - birthYear;
      ageText = 'Năm sinh $birthYear ($age tuổi)';
    }

    // Giới tính
    String genderText = 'Khác';
    if (gender == 'male') {
      genderText = 'Nam';
    } else if (gender == 'female') {
      genderText = 'Nữ';
    } else if (gender?.isNotEmpty == true) {
      genderText = gender!;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'THÔNG TIN CÁ NHÂN',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.cake_outlined,
            iconColor: const Color(0xFFFFD428),
            label: 'Ngày sinh / Tuổi',
            value: showAge ? ageText : 'Ẩn theo riêng tư 🔒',
            isPrivate: !showAge,
          ),
          const Divider(height: 20),
          _InfoTile(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.cyan,
            label: 'Nơi ở hiện tại',
            value: showLocation ? locationText : 'Ẩn theo riêng tư 🔒',
            isPrivate: !showLocation,
          ),
          const Divider(height: 20),
          _InfoTile(
            icon: Icons.school_outlined,
            iconColor: const Color(0xFFC084FC),
            label: 'Học vấn / Trường học',
            value: education?.isNotEmpty == true
                ? education!
                : 'Đại học Bách Khoa TP.HCM',
          ),
          const Divider(height: 20),
          _InfoTile(
            icon: Icons.wc_outlined,
            iconColor: Colors.pinkAccent,
            label: 'Giới tính',
            value: genderText,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isPrivate = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isPrivate;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isPrivate ? AppColors.muted : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

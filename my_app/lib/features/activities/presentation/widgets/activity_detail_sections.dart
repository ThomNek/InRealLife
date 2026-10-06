import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Các khối section nội dung trong trang chi tiết hoạt động
class ActivityDetailSections extends StatelessWidget {
  const ActivityDetailSections({
    super.key,
    required this.description,
    required this.locationName,
    required this.address,
    required this.preparationNotes,
    required this.teams,
  });

  final String description;
  final String locationName;
  final String address;
  final String preparationNotes;
  final List<Map<String, dynamic>> teams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Một hành trình để cùng khám phá',
          child: Text(
            description.isEmpty
                ? 'Người tổ chức chưa thêm mô tả.'
                : description,
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Điểm hẹn và an toàn',
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.location_on_outlined,
                title: locationName,
                subtitle: address,
              ),
              const SizedBox(height: 12),
              const _DetailRow(
                icon: Icons.shield_outlined,
                title: 'Hoạt động đã kiểm tra an toàn',
                subtitle: 'Không đi vào khu vực riêng tư hoặc nguy hiểm',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Bạn cần chuẩn bị',
          child: Text(
            preparationNotes.isEmpty
                ? 'Người tổ chức chưa thêm vật dụng hoặc quy tắc riêng.'
                : preparationNotes,
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Đội đang tham gia',
          child: teams.isEmpty
              ? const Text(
                  'Chưa có đội cho hoạt động này.',
                  style: TextStyle(color: AppColors.muted),
                )
              : Column(
                  children: teams
                      .map(
                        (team) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.groups_rounded),
                          ),
                          title: Text(
                            team['name'] as String? ?? 'Đội',
                          ),
                          subtitle: Text(
                            '${_teamMemberCount(team)}/${team['max_members'] ?? '?'} thành viên',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/teams/detail',
                            arguments: team['id'] as String?,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  int _teamMemberCount(Map<String, dynamic> team) {
    final counts = team['team_members'] as List?;
    if (counts == null || counts.isEmpty) return 0;
    return ((counts.first as Map<String, dynamic>)['count'] as num?)?.toInt() ??
        0;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: const TextStyle(color: Color(0xFFC6CEDF), height: 1.55),
              child: child,
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.cyan),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
}

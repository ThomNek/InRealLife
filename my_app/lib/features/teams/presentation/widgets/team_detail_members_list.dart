import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Khối hiển thị danh sách thành viên trong đội
class TeamDetailMembersList extends StatelessWidget {
  const TeamDetailMembersList({
    super.key,
    required this.members,
    required this.isHost,
    required this.isRequesting,
    required this.onKickMember,
  });

  final List<Map<String, dynamic>> members;
  final bool isHost;
  final bool isRequesting;
  final ValueChanged<String> onKickMember;

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
            'Thành viên',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          members.isEmpty
              ? const Text(
                  'Chưa có thành viên.',
                  style: TextStyle(color: AppColors.muted),
                )
              : Column(
                  children: members.map((member) {
                    final profile =
                        member['profiles'] as Map<String, dynamic>?;
                    final name =
                        profile?['display_name'] as String? ?? 'Người dùng';
                    final host = member['role'] == 'host';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(host ? 'Chủ đội' : 'Thành viên'),
                      trailing: host
                          ? const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.orange,
                            )
                          : isHost
                              ? IconButton(
                                  tooltip: 'Kích khỏi đội',
                                  onPressed: isRequesting
                                      ? null
                                      : () => onKickMember(
                                            member['user_id'] as String,
                                          ),
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    color: Colors.redAccent,
                                  ),
                                )
                              : null,
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

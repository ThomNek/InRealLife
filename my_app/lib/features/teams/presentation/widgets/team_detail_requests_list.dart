import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Khối hiển thị danh sách yêu cầu tham gia chờ duyệt dành cho Host
class TeamDetailRequestsList extends StatelessWidget {
  const TeamDetailRequestsList({
    super.key,
    required this.pendingRequests,
    required this.isRequesting,
    required this.onApprove,
    required this.onReject,
  });

  final List<Map<String, dynamic>> pendingRequests;
  final bool isRequesting;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

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
          Text(
            'Yêu cầu tham gia (${pendingRequests.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          pendingRequests.isEmpty
              ? const Text(
                  'Chưa có yêu cầu đang chờ.',
                  style: TextStyle(color: AppColors.muted),
                )
              : Column(
                  children: pendingRequests.map((request) {
                    final profile =
                        request['profiles'] as Map<String, dynamic>?;
                    final name =
                        profile?['display_name'] as String? ?? 'Người dùng';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        request['message'] as String? ??
                            'Muốn tham gia đội',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Từ chối',
                            onPressed: isRequesting
                                ? null
                                : () => onReject(request['id'] as String),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.redAccent,
                            ),
                          ),
                          IconButton.filled(
                            tooltip: 'Duyệt',
                            onPressed: isRequesting
                                ? null
                                : () => onApprove(request['id'] as String),
                            icon: const Icon(Icons.check_rounded),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

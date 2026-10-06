import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Khối tác vụ chính của trang chi tiết đội (Xin gia nhập, Rời đội, Mở chat)
class TeamDetailActions extends StatelessWidget {
  const TeamDetailActions({
    super.key,
    required this.teamId,
    required this.isHost,
    required this.isMember,
    required this.requestStatus,
    required this.isRequesting,
    required this.onRequestToJoin,
    required this.onCancelRequest,
    required this.onLeaveTeam,
  });

  final String? teamId;
  final bool isHost;
  final bool isMember;
  final String? requestStatus;
  final bool isRequesting;
  final VoidCallback onRequestToJoin;
  final VoidCallback onCancelRequest;
  final VoidCallback onLeaveTeam;

  @override
  Widget build(BuildContext context) {
    if (isHost) {
      return Column(
        children: [
          const ListTile(
            leading: Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.orange,
            ),
            title: Text(
              'Bạn là chủ đội',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('Quản lý yêu cầu tham gia và thành viên.'),
          ),
          _teamChatButton(context),
        ],
      );
    }
    if (isMember) {
      return Column(
        children: [
          const ListTile(
            leading: Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
            ),
            title: Text('Bạn đã tham gia đội'),
          ),
          _teamChatButton(context),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isRequesting ? null : onLeaveTeam,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Rời đội'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      );
    }
    if (requestStatus == 'pending') {
      return Column(
        children: [
          const ListTile(
            leading: Icon(Icons.schedule_rounded, color: AppColors.orange),
            title: Text('Yêu cầu đang chờ duyệt'),
          ),
          OutlinedButton(
            onPressed: isRequesting ? null : onCancelRequest,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      );
    }
    return FilledButton.icon(
      onPressed: isRequesting ? null : onRequestToJoin,
      icon: const Icon(Icons.group_add_rounded),
      label: Text(isRequesting ? 'Đang gửi...' : 'Xin tham gia đội'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
    );
  }

  Widget _teamChatButton(BuildContext context) => FilledButton.icon(
        onPressed: () =>
            Navigator.pushNamed(context, '/teams/chat', arguments: teamId),
        icon: const Icon(Icons.forum_rounded),
        label: const Text('Mở chat đội'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      );
}

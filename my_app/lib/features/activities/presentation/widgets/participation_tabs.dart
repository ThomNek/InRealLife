import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'activity_filter_modal.dart';

/// Phần giao diện của bốn tab trong trang Tham gia hoạt động.
///
/// Widget này nhận dữ liệu từ Supabase backend (Future & Callbacks) từ [ParticipationPage]
/// và hiển thị danh sách hoạt động, đội nhóm dưới dạng Card chi tiết.
class ParticipationTabs extends StatelessWidget {
  const ParticipationTabs({
    super.key,
    required this.activities,
    required this.myActivities,
    required this.myTeams,
    required this.recruitingTeams,
    required this.onOpenActivity,
    required this.onOpenTeam,
    required this.onCreateTeam,
    this.filterState = const ActivityFilterState(),
  });

  final Future<List<Map<String, dynamic>>> activities;
  final Future<List<Map<String, dynamic>>> myActivities;
  final Future<List<Map<String, dynamic>>> myTeams;
  final Future<List<Map<String, dynamic>>> recruitingTeams;
  final ValueChanged<Map<String, dynamic>> onOpenActivity;
  final ValueChanged<Map<String, dynamic>> onOpenTeam;
  final VoidCallback onCreateTeam;
  final ActivityFilterState filterState;

  @override
  Widget build(BuildContext context) => TabBarView(
        children: [
          ActivityListFuture(
            future: activities,
            empty: 'Chưa có hoạt động công khai.',
            onOpenActivity: onOpenActivity,
            filterState: filterState,
          ),
          ActivityListFuture(
            future: myActivities,
            empty: 'Bạn chưa tạo hoạt động nào.',
            onOpenActivity: onOpenActivity,
            filterState: filterState,
          ),
          MyTeamsTab(
            future: myTeams,
            onOpenTeam: onOpenTeam,
            filterState: filterState,
          ),
          RecruitingTeamsTab(
            future: recruitingTeams,
            onOpenTeam: onOpenTeam,
            onCreateTeam: onCreateTeam,
            filterState: filterState,
          ),
        ],
      );
}

class ActivityListFuture extends StatelessWidget {
  const ActivityListFuture({
    super.key,
    required this.future,
    required this.empty,
    required this.onOpenActivity,
    this.filterState = const ActivityFilterState(),
  });

  final Future<List<Map<String, dynamic>>> future;
  final String empty;
  final ValueChanged<Map<String, dynamic>> onOpenActivity;
  final ActivityFilterState filterState;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: 'Không thể tải hoạt động: ${snapshot.error}',
            );
          }
          final rawRows = snapshot.data ?? const [];
          final rows = filterState.filterList(rawRows);
          if (rows.isEmpty) {
            return Center(
              child: Text(
                filterState.isFiltered
                    ? 'Không tìm thấy hoạt động phù hợp với bộ lọc.'
                    : empty,
                style: const TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final row = rows[index];
              return _ActivityCardItem(
                activity: row,
                onTap: () => onOpenActivity(row),
              );
            },
          );
        },
      );
}

class MyTeamsTab extends StatelessWidget {
  const MyTeamsTab({
    super.key,
    required this.future,
    required this.onOpenTeam,
    this.filterState = const ActivityFilterState(),
  });

  final Future<List<Map<String, dynamic>>> future;
  final ValueChanged<Map<String, dynamic>> onOpenTeam;
  final ActivityFilterState filterState;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: 'Không thể tải đội của bạn: ${snapshot.error}',
            );
          }

          final rawTeams = (snapshot.data ?? const <Map<String, dynamic>>[])
              .map((membership) => membership['teams'])
              .whereType<Map<String, dynamic>>()
              .toList();
          final teams = filterState.filterList(rawTeams);
          if (teams.isEmpty) {
            return Center(
              child: Text(
                filterState.isFiltered
                    ? 'Không tìm thấy đội phù hợp với bộ lọc.'
                    : 'Bạn chưa tham gia đội nào.',
                style: const TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final row = teams[index];
              return _TeamCardItem(
                team: row,
                actionLabel: 'Quản lý / Xem',
                onTap: () => onOpenTeam(row),
              );
            },
          );
        },
      );
}

class RecruitingTeamsTab extends StatelessWidget {
  const RecruitingTeamsTab({
    super.key,
    required this.future,
    required this.onOpenTeam,
    required this.onCreateTeam,
    this.filterState = const ActivityFilterState(),
  });

  final Future<List<Map<String, dynamic>>> future;
  final ValueChanged<Map<String, dynamic>> onOpenTeam;
  final VoidCallback onCreateTeam;
  final ActivityFilterState filterState;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LoadError(
                    message: 'Không thể tải đội: ${snapshot.error}',
                  );
                }
                final rawRows = snapshot.data ?? const [];
                final rows = filterState.filterList(rawRows);
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      filterState.isFiltered
                          ? 'Không tìm thấy đội phù hợp với bộ lọc.'
                          : 'Chưa có đội nào đang tuyển.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final row = rows[index];
                    final isPending = row['my_request_status'] == 'pending';
                    return _TeamCardItem(
                      team: row,
                      actionLabel: isPending ? 'Chờ duyệt' : 'Xem đội',
                      onTap: () => onOpenTeam(row),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: onCreateTeam,
              icon: const Icon(Icons.groups_rounded),
              label: const Text('Tạo đội mới'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      );
}

class _ActivityCardItem extends StatelessWidget {
  const _ActivityCardItem({required this.activity, required this.onTap});

  final Map<String, dynamic> activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (activity['title'] as String?) ?? 'Hoạt động';
    final location =
        (activity['location_name'] as String?) ?? 'Chưa có địa điểm';
    final status = (activity['status'] as String?) ?? 'open';
    final type = (activity['type'] as String?) ?? 'treasure_hunt';
    final distanceText =
        _formatDistance(activity['distance_km'] ?? activity['distance']);

    final profile = activity['profiles'] as Map<String, dynamic>?;
    final hostName = (activity['host_name'] as String?) ??
        (activity['creator_name'] as String?) ??
        (profile?['display_name'] as String?) ??
        (profile?['username'] as String?) ??
        'Thành viên';

    final teamsList = activity['teams'] as List<dynamic>?;
    final firstTeam = teamsList != null && teamsList.isNotEmpty
        ? teamsList.first as Map<String, dynamic>?
        : null;
    final targetGender = (activity['target_gender'] as String?) ??
        (firstTeam?['target_gender'] as String?) ??
        'all';
    final joinPolicy = (activity['join_policy'] as String?) ??
        (firstTeam?['join_policy'] as String?) ??
        'everyone';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActivityTypeBadge(type: type),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 11,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _FilterTag(label: _genderLabel(targetGender)),
              _FilterTag(label: _policyLabel(joinPolicy)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Host: $hostName',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Xem hoạt động'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamCardItem extends StatelessWidget {
  const _TeamCardItem({
    required this.team,
    required this.actionLabel,
    required this.onTap,
  });

  final Map<String, dynamic> team;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (team['name'] as String?) ?? 'Đội chưa đặt tên';
    final area = (team['meeting_area'] as String?) ?? 'Chưa có điểm hẹn';
    final targetGender = (team['target_gender'] as String?) ?? 'all';
    final joinPolicy = (team['join_policy'] as String?) ?? 'everyone';
    final counts = team['team_members'] as List?;
    final memberCount = counts?.isNotEmpty == true
        ? (counts!.first as Map<String, dynamic>)['count'] ?? 1
        : 1;
    final maxMembers = team['max_members'] ?? 4;
    final distanceText =
        _formatDistance(team['distance_km'] ?? team['distance']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$memberCount/$maxMembers người',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  area,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 11,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              _FilterTag(label: _genderLabel(targetGender)),
              _FilterTag(label: _policyLabel(joinPolicy)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _genderLabel(String gender) {
  switch (gender) {
    case 'female_only':
      return '👩 Chỉ nữ';
    case 'male_only':
      return '👨 Chỉ nam';
    default:
      return '👥 Nam & Nữ';
  }
}

String _policyLabel(String policy) {
  switch (policy) {
    case 'friends_only':
      return '🤝 Chỉ bạn bè';
    default:
      return '🌐 Mọi người';
  }
}

class _ActivityTypeBadge extends StatelessWidget {
  const _ActivityTypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    String label = '💎 SĂN KHO BÁU';
    Color color = AppColors.cyan;

    if (type == 'walking') {
      label = '🏃 ĐI BỘ';
      color = const Color(0xFFC084FC);
    } else if (type == 'exchange') {
      label = '🧩 ĐỔI MẢNH';
      color = AppColors.orange;
    } else if (type == 'sport') {
      label = '🎾 THỂ THAO';
      color = const Color(0xFFFFD22E);
    } else if (type == 'coffee') {
      label = '☕ CÀ PHÊ';
      color = AppColors.orange;
    } else if (type == 'board_game') {
      label = '🎲 BOARD GAME';
      color = Colors.purpleAccent;
    } else if (type == 'other') {
      label = '⚡ GIAO LƯU';
      color = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

String _formatDistance(dynamic raw) {
  if (raw == null) return '1.2 km';
  if (raw is num) {
    if (raw < 1) return '${(raw * 1000).round()} m';
    return '${raw.toStringAsFixed(1)} km';
  }
  final str = raw.toString();
  if (str.isEmpty) return '1.2 km';
  return str.contains('km') || str.contains('m') ? str : '$str km';
}

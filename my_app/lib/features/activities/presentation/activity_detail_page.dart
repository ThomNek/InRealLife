import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/activity_repository.dart';
import 'widgets/activity_detail_bottom_bar.dart';
import 'widgets/activity_detail_header.dart';
import 'widgets/activity_detail_info_chips.dart';
import 'widgets/activity_detail_sections.dart';

/// Trang Chi tiết hoạt động (Modular UI Page)
class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final _repository = ActivityRepository();
  String? _activityId;
  Future<_ActivityDetailData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _activityId) {
      _activityId = id;
      _future = _load(id);
    }
  }

  Future<_ActivityDetailData> _load(String id) async {
    final results = await Future.wait([
      _repository.fetchActivity(id),
      _repository.fetchActivityTeams(id),
    ]);
    return _ActivityDetailData(
      results[0] as Map<String, dynamic>,
      results[1] as List<Map<String, dynamic>>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const Scaffold(
        body: Center(child: Text('Không xác định được hoạt động.')),
      );
    }
    return FutureBuilder<_ActivityDetailData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết hoạt động')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Không thể tải hoạt động: ${snapshot.error}'),
              ),
            ),
          );
        }
        return _buildPage(snapshot.data!);
      },
    );
  }

  Widget _buildPage(_ActivityDetailData data) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    Map<String, dynamic>? hostTeam;
    if (currentUserId != null) {
      for (final t in data.teams) {
        if (t['host_id'] == currentUserId) {
          hostTeam = t;
          break;
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ActivityDetailHeader(
            title: data.title,
            typeLabel: data.typeLabel,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ActivityDetailInfoChips(
                        startsAtLabel: data.startsAtLabel,
                        statusLabel: data.statusLabel,
                        skillLevelLabel: data.skillLevelLabel,
                        memberCount: data.memberCount,
                        maxMembers: data.maxMembers,
                      ),
                      const SizedBox(height: 18),
                      ActivityDetailSections(
                        description: data.description,
                        locationName: data.locationName,
                        address: data.address,
                        preparationNotes: data.preparationNotes,
                        teams: data.teams,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActivityDetailBottomBar(
        hostTeam: hostTeam,
        teams: data.teams,
      ),
    );
  }
}

class _ActivityDetailData {
  const _ActivityDetailData(this.activity, this.teams);

  final Map<String, dynamic> activity;
  final List<Map<String, dynamic>> teams;

  String get title => activity['title'] as String? ?? 'Hoạt động';
  String get description => activity['description'] as String? ?? '';
  String get locationName =>
      activity['location_name'] as String? ?? 'Chưa cập nhật địa điểm';
  String get address => activity['address'] as String? ?? 'Địa điểm công cộng';
  String get preparationNotes => activity['preparation_notes'] as String? ?? '';
  int get maxMembers => (activity['max_members'] as num?)?.toInt() ?? 0;
  int get memberCount => teams.fold<int>(0, (total, team) {
        final counts = team['team_members'] as List?;
        if (counts == null || counts.isEmpty) return total;
        final count = (counts.first as Map<String, dynamic>)['count'] as num?;
        return total + (count?.toInt() ?? 0);
      });

  String get typeLabel => switch (activity['type']) {
        'coffee' => 'Cà phê',
        'sport' => 'Thể thao',
        'treasure_hunt' => 'Săn kho báu',
        'walking' => 'Đi bộ',
        'board_game' => 'Board game',
        _ => 'Hoạt động ngoài đời',
      };

  String get statusLabel => switch (activity['status']) {
        'open' => 'Đang mở',
        'full' => 'Đã đủ người',
        'ongoing' => 'Đang diễn ra',
        'completed' => 'Đã hoàn thành',
        'cancelled' => 'Đã hủy',
        _ => 'Chưa xác định',
      };

  String get skillLevelLabel => switch (activity['skill_level']) {
        'beginner' => 'Mới bắt đầu',
        'basic' => 'Cơ bản',
        'intermediate' => 'Trung bình',
        'advanced' => 'Nâng cao',
        _ => 'Mọi trình độ',
      };

  String get startsAtLabel {
    final value = activity['starts_at'] as String?;
    final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Chưa cập nhật thời gian';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} · ${two(date.hour)}:${two(date.minute)}';
  }
}

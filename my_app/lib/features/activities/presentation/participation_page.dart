import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_navigation_shell.dart';
import '../../teams/data/team_repository.dart';
import '../data/activity_repository.dart';
import 'widgets/activity_filter_modal.dart';
import 'widgets/participation_tabs.dart';

class ParticipationPage extends StatefulWidget {
  const ParticipationPage({super.key});

  @override
  State<ParticipationPage> createState() => _ParticipationPageState();
}

class _ParticipationPageState extends State<ParticipationPage>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _activities;
  late Future<List<Map<String, dynamic>>> _myActivities;
  late Future<List<Map<String, dynamic>>> _teams;
  late Future<List<Map<String, dynamic>>> _myTeams;
  late final StreamSubscription<AuthState> _authSubscription;
  final List<StreamSubscription<List<Map<String, dynamic>>>>
  _dataSubscriptions = [];
  Timer? _reloadDebounce;
  String? _loadedUserId;
  bool _realtimeWarningShown = false;
  ActivityFilterState _filterState = const ActivityFilterState();

  Future<void> _openFilterModal() async {
    final result = await showActivityFilterModal(context, _filterState);
    if (result != null && mounted) {
      setState(() => _filterState = result);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final auth = Supabase.instance.client.auth;
    _loadedUserId = auth.currentUser?.id;
    _reload();
    _listenToDataChanges();
    _authSubscription = auth.onAuthStateChange.listen(_handleAuthChange);
  }

  void _listenToDataChanges() {
    for (final subscription in _dataSubscriptions) {
      unawaited(subscription.cancel());
    }
    _dataSubscriptions.clear();

    final client = Supabase.instance.client;
    _dataSubscriptions.addAll([
      client
          .from('activities')
          .stream(primaryKey: ['id'])
          .listen(_handleRealtimeData, onError: _handleRealtimeError),
      client
          .from('teams')
          .stream(primaryKey: ['id'])
          .listen(_handleRealtimeData, onError: _handleRealtimeError),
      client
          .from('team_members')
          .stream(primaryKey: ['team_id', 'user_id'])
          .listen(_handleRealtimeData, onError: _handleRealtimeError),
      client
          .from('team_requests')
          .stream(primaryKey: ['id'])
          .listen(_handleRealtimeData, onError: _handleRealtimeError),
    ]);
  }

  void _handleRealtimeData(List<Map<String, dynamic>> _) {
    _realtimeWarningShown = false;
    _scheduleReload();
  }

  void _handleRealtimeError(Object _) {
    if (!mounted || _realtimeWarningShown) return;
    _realtimeWarningShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cập nhật Realtime bị gián đoạn. Bạn có thể bấm làm mới.',
        ),
      ),
    );
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(_reload);
    });
  }

  void _reload() {
    _activities = ActivityRepository().fetchPublicActivities();
    _myActivities = ActivityRepository().fetchMyActivities();
    _teams = TeamRepository().fetchRecruitingTeams();
    _myTeams = TeamRepository().fetchMyTeams();
  }

  void _handleAuthChange(AuthState state) {
    final nextUserId = state.session?.user.id;
    if (nextUserId == _loadedUserId) return;

    _loadedUserId = nextUserId;
    if (!mounted) return;

    if (nextUserId == null) {
      // Đưa người dùng về route gốc để AuthGate hiển thị trang đăng nhập.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // Trang này có thể vẫn nằm trên navigation stack khi đổi tài khoản.
    // Tạo Future mới để không tiếp tục hiển thị kết quả của tài khoản trước.
    setState(_reload);
    _listenToDataChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloadDebounce?.cancel();
    for (final subscription in _dataSubscriptions) {
      unawaited(subscription.cancel());
    }
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => MainShell(
        selectedIndex: 2,
        child: DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Tham gia hoạt động',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'Bộ lọc',
                  onPressed: _openFilterModal,
                  icon: _filterState.isFiltered
                      ? Badge(
                          label: Text('${_filterState.activeCount}'),
                          child: const Icon(Icons.tune_rounded),
                        )
                      : const Icon(Icons.tune_rounded),
                ),
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Khám phá'),
                  Tab(text: 'Hoạt động của tôi'),
                  Tab(text: 'Đội của tôi'),
                  Tab(text: 'Đội đang tuyển'),
                ],
              ),
            ),
            body: Column(
              children: [
                ActivityFilterSummaryBar(
                  filterState: _filterState,
                  onReset: () => setState(
                    () => _filterState = const ActivityFilterState(),
                  ),
                  onOpenFilter: _openFilterModal,
                ),
                Expanded(
                  child: ParticipationTabs(
                    activities: _activities,
                    myActivities: _myActivities,
                    myTeams: _myTeams,
                    recruitingTeams: _teams,
                    onOpenActivity: _openActivity,
                    onOpenTeam: _openTeam,
                    onCreateTeam: () =>
                        Navigator.pushNamed(context, '/teams/create'),
                    filterState: _filterState,
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.pushNamed(
                  context,
                  '/activities/create',
                );
                if (created == true && mounted) setState(_reload);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo hoạt động'),
            ),
          ),
        ),
      );

  void _refresh() {
    _realtimeWarningShown = false;
    _listenToDataChanges();
    setState(_reload);
  }

  Future<void> _openActivity(Map<String, dynamic> activity) async {
    final activityId = activity['id'] as String?;
    if (activityId != null) {
      final hostTeam = await TeamRepository().findHostTeamForActivity(activityId);
      if (hostTeam != null && mounted) {
        await Navigator.pushNamed(
          context,
          '/teams/detail',
          arguments: hostTeam['id'] as String?,
        );
        if (mounted) setState(_reload);
        return;
      }
    }
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      '/activities/sunset',
      arguments: activityId,
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openTeam(Map<String, dynamic> team) async {
    await Navigator.pushNamed(
      context,
      '/teams/detail',
      arguments: team['id'] as String?,
    );
    if (mounted) setState(_reload);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/team_repository.dart';
import 'widgets/team_detail_actions.dart';
import 'widgets/team_detail_header.dart';
import 'widgets/team_detail_members_list.dart';
import 'widgets/team_detail_requests_list.dart';

/// Trang Chi tiết đội (Modular UI Page)
class TeamDetailPage extends StatefulWidget {
  const TeamDetailPage({super.key, this.repository, this.teamId});

  final TeamRepository? repository;
  final String? teamId;

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage>
    with WidgetsBindingObserver {
  late final TeamRepository _repository;
  String? _teamId;
  Future<_TeamViewData>? _future;
  bool _requesting = false;
  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _membersSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _teamSubscription;
  Timer? _reloadDebounce;
  bool _realtimeWarningShown = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TeamRepository();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id =
        widget.teamId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _teamId) {
      _teamId = id;
      _future = _load(id);
      _listenToTeamChanges(id);
    }
  }

  void _listenToTeamChanges(String teamId) {
    unawaited(_requestsSubscription?.cancel());
    unawaited(_membersSubscription?.cancel());
    unawaited(_teamSubscription?.cancel());

    _teamSubscription = _repository.watchTeam(teamId).listen((_) {
      _realtimeWarningShown = false;
      _scheduleReload();
    }, onError: _handleRealtimeError);
    _requestsSubscription = _repository.watchTeamRequests(teamId).listen((_) {
      _realtimeWarningShown = false;
      _scheduleReload();
    }, onError: _handleRealtimeError);
    _membersSubscription = _repository.watchTeamMembers(teamId).listen((_) {
      _realtimeWarningShown = false;
      _scheduleReload();
    }, onError: _handleRealtimeError);
  }

  void _handleRealtimeError(Object _) {
    if (!mounted || _realtimeWarningShown) return;
    _realtimeWarningShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kết nối Realtime bị gián đoạn. Bạn có thể bấm làm mới.'),
      ),
    );
  }

  void _reloadNow() {
    final teamId = _teamId;
    if (teamId == null) return;
    _realtimeWarningShown = false;
    _listenToTeamChanges(teamId);
    final nextData = _load(teamId);
    setState(() {
      _future = nextData;
    });
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || _teamId == null) return;
      final nextData = _load(_teamId!);
      setState(() {
        _future = nextData;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloadDebounce?.cancel();
    unawaited(_requestsSubscription?.cancel());
    unawaited(_membersSubscription?.cancel());
    unawaited(_teamSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _reloadNow();
  }

  Future<_TeamViewData> _load(String id) async {
    final team = await _repository.fetchTeam(id);
    final members = await _repository.fetchTeamMembers(id);
    final request = await _repository.fetchMyRequest(id);
    final isHost = team['host_id'] == _repository.currentUserId;
    final pending = isHost
        ? await _repository.fetchPendingRequests(id)
        : <Map<String, dynamic>>[];
    return _TeamViewData(
      team,
      members,
      request,
      pending,
      _repository.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const Scaffold(
        body: Center(child: Text('Không xác định được đội.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đội'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _reloadNow,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_TeamViewData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Không thể tải đội: ${snapshot.error}'));
          }
          return _content(snapshot.data!);
        },
      ),
    );
  }

  Widget _content(_TeamViewData data) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  TeamDetailHeader(
                    name: data.name,
                    memberCount: data.members.length,
                    maxMembers: data.maxMembers,
                    description: data.description,
                  ),
                  const SizedBox(height: 14),
                  TeamDetailMembersList(
                    members: data.members,
                    isHost: data.isHost,
                    isRequesting: _requesting,
                    onKickMember: _kick,
                  ),
                  const SizedBox(height: 14),
                  if (data.isHost) ...[
                    TeamDetailRequestsList(
                      pendingRequests: data.pendingRequests,
                      isRequesting: _requesting,
                      onApprove: _approve,
                      onReject: _reject,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _meetingPlanBlock(data),
                  const SizedBox(height: 16),
                  TeamDetailActions(
                    teamId: _teamId,
                    isHost: data.isHost,
                    isMember: data.isMember,
                    requestStatus: data.requestStatus,
                    isRequesting: _requesting,
                    onRequestToJoin: _request,
                    onCancelRequest: _cancelRequest,
                    onLeaveTeam: _leaveTeam,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _meetingPlanBlock(_TeamViewData data) => Container(
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
              'Kế hoạch gặp mặt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.location_on_outlined,
                color: Colors.greenAccent,
              ),
              title: Text(data.meetingArea),
              subtitle: Text(data.meetingAt),
            ),
          ],
        ),
      );

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      await _repository.requestToJoin(_teamId!);
      if (!mounted) return;
      setState(() {
        _future = _load(_teamId!);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi yêu cầu: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _approve(String requestId) => _manageBusy(
        () => _repository.approveRequest(requestId),
        'Đã duyệt thành viên.',
      );

  Future<void> _reject(String requestId) => _manageBusy(
        () => _repository.rejectRequest(requestId),
        'Đã từ chối yêu cầu.',
      );

  Future<void> _kick(String userId) => _manageBusy(
        () => _repository.kickMember(_teamId!, userId),
        'Đã đưa thành viên khỏi đội.',
      );

  Future<void> _cancelRequest() => _manageBusy(
        () => _repository.cancelJoinRequest(_teamId!),
        'Đã hủy yêu cầu tham gia.',
      );

  Future<void> _leaveTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời đội?'),
        content: const Text(
          'Bạn sẽ không còn xem được chat đội và phải gửi yêu cầu mới nếu muốn quay lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rời đội'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _manageBusy(() => _repository.leaveTeam(_teamId!), 'Bạn đã rời đội.');
  }

  Future<void> _manageBusy(
    Future<void> Function() action,
    String success,
  ) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await _manage(action, success);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _manage(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
      setState(() {
        _future = _load(_teamId!);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Thao tác thất bại: $error')));
      }
    }
  }
}

class _TeamViewData {
  const _TeamViewData(
    this.team,
    this.members,
    this.request,
    this.pendingRequests,
    this.currentUserId,
  );
  final Map<String, dynamic> team;
  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? request;
  final List<Map<String, dynamic>> pendingRequests;
  final String? currentUserId;
  String get name => team['name'] as String? ?? 'Đội chưa đặt tên';
  String get description => team['description'] as String? ?? '';
  int get maxMembers => team['max_members'] as int? ?? 0;
  String get meetingArea =>
      team['meeting_area'] as String? ?? 'Chưa cập nhật địa điểm';
  String get meetingAt {
    final raw = team['meeting_at'] as String?;
    final value = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (value == null) return 'Chưa cập nhật thời gian';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} · '
        '${two(value.hour)}:${two(value.minute)}';
  }

  bool get isHost => team['host_id'] == currentUserId;
  bool get isMember =>
      members.any((member) => member['user_id'] == currentUserId);
  String? get requestStatus => request?['status'] as String?;
}

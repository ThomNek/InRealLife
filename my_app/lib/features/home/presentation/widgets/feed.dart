import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../activities/data/activity_repository.dart';
import 'top_bar.dart';

const String _bannerAsset = 'assets/images/banners/AnhSuoi.jpg';

const TextStyle _kickerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w900,
  color: AppColors.muted,
);

class HomeFeed extends StatelessWidget {
  const HomeFeed({
    super.key,
    required this.controller,
    required this.compact,
    required this.mobile,
    required this.profile,
  });

  final ScrollController controller;
  final bool compact;
  final bool mobile;
  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: controller,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          mobile ? 12 : 0,
          mobile ? 12 : 0,
          mobile ? 12 : 0,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeTopBar(mobile: mobile, profile: profile),
            const SizedBox(height: 16),
            const _EventBanner(),
            const SizedBox(height: 16),
            const _ConnectCard(),
            const SizedBox(height: 16),
            _RadarCard(compact: compact),
            const SizedBox(height: 16),
            const _DailyClue(),
            const SizedBox(height: 22),
            const _RecentActivitiesHeader(),
            const SizedBox(height: 12),
            const _DynamicFeedActivities(),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/activities'),
              child: const Text('Xem tất cả hoạt động'),
            ),
            const SizedBox(height: 16),
            const _LobbyCard(),
          ],
        ),
      );
}

class _EventBanner extends StatelessWidget {
  const _EventBanner();

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 190),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: const DecorationImage(
            image: AssetImage(_bannerAsset),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xEE121624), Color(0x77121624)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SỰ KIỆN MÙA HÈ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Cuộc đi săn kho báu\nThành phố 2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hơn 50 rương ẩn đã được tạo ngẫu nhiên. Lập đội ngay để mở rương!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Tham gia ngay',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF2A3C53),
              child: Icon(Icons.people_outline_rounded, color: AppColors.cyan),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kết nối thợ săn quanh bạn',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tìm đồng đội có cùng sở thích khám phá ngoài đời thực.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Ghép đội'),
            ),
          ],
        ),
      );
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RADAR THỜI GIAN THỰC', style: _kickerStyle),
                      SizedBox(height: 3),
                      Text(
                        'Kho báu & Hoạt động gần bạn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _NearbyBadge(),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: const Color(0xFF161B2E),
                      child: CustomPaint(
                        painter: _RadarPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDD121624),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                color: AppColors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Bán kính: 3,0 km',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '3 kho báu · 2 đội đang mở',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = const Color(0xFF26334D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintDot = Paint()..style = PaintingStyle.fill;

    // Vòng tròn radar
    canvas.drawCircle(center, size.height * 0.2, paintLine);
    canvas.drawCircle(center, size.height * 0.38, paintLine);

    // Vị trí bản thân
    paintDot.color = AppColors.orange;
    canvas.drawCircle(center, 7, paintDot);

    // Điểm kho báu 1
    paintDot.color = const Color(0xFFFFD428);
    canvas.drawCircle(
      Offset(center.dx + 45, center.dy - 35),
      6,
      paintDot,
    );

    // Điểm kho báu 2
    canvas.drawCircle(
      Offset(center.dx - 65, center.dy + 25),
      6,
      paintDot,
    );

    // Điểm Đội đang mở
    paintDot.color = AppColors.cyan;
    canvas.drawCircle(
      Offset(center.dx + 75, center.dy + 40),
      6,
      paintDot,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DailyClue extends StatelessWidget {
  const _DailyClue();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF323F5C)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.extension_rounded,
              color: Color(0xFFFFD428),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manh mối hàng ngày #142',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD428),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '«Nơi ba con đường giao nhau dưới bóng cây cổ thụ lớn nhất...»',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
          ],
        ),
      );
}

class _RecentActivitiesHeader extends StatelessWidget {
  const _RecentActivitiesHeader();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THỜI GIAN THỰC', style: _kickerStyle),
                SizedBox(height: 3),
                Text(
                  'Hoạt động gần đây',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Gần bạn')),
              ButtonSegment(value: 1, label: Text('Mới nhất')),
            ],
            selected: const {0},
            onSelectionChanged: (_) {},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
            ),
          ),
        ],
      );
}

class _DynamicFeedActivities extends StatefulWidget {
  const _DynamicFeedActivities();

  @override
  State<_DynamicFeedActivities> createState() => _DynamicFeedActivitiesState();
}

class _DynamicFeedActivitiesState extends State<_DynamicFeedActivities> {
  final ActivityRepository _repository = ActivityRepository();
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    _activitiesFuture = _repository.fetchFeedActivities(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return _FeedCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(
                    Icons.explore_off_outlined,
                    color: AppColors.muted,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chưa có hoạt động nào trong cộng đồng.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pushNamed(context, '/activities/create'),
                    child: const Text('Tạo hoạt động đầu tiên'),
                  ),
                ],
              ),
            ),
          );
        }

        // Đảm bảo chỉ hiển thị tối đa 5 hoạt động
        final displayList = activities.take(5).toList();

        return Column(
          children: displayList.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DynamicActivityFeedCard(activity: activity),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DynamicActivityFeedCard extends StatelessWidget {
  const _DynamicActivityFeedCard({required this.activity});

  final Map<String, dynamic> activity;

  static String _genderLabel(String gender) {
    switch (gender) {
      case 'female_only':
        return '👩 Chỉ nữ';
      case 'male_only':
        return '👨 Chỉ nam';
      default:
        return '👥 Nam & Nữ';
    }
  }

  static String _policyLabel(String policy) {
    switch (policy) {
      case 'friends_only':
        return '🤝 Chỉ bạn bè';
      default:
        return '🌐 Mọi người';
    }
  }

  static (String, Color, IconData) _typeInfo(String type) {
    switch (type) {
      case 'treasure_hunt':
        return ('💎 SĂN KHO BÁU', AppColors.cyan, Icons.explore_rounded);
      case 'walking':
        return ('🏃 ĐI BỘ', const Color(0xFFC084FC), Icons.directions_walk_rounded);
      case 'sport':
        return ('🎾 THỂ THAO', const Color(0xFFFFD22E), Icons.sports_tennis_rounded);
      case 'coffee':
        return ('☕ CÀ PHÊ', AppColors.orange, Icons.local_cafe_rounded);
      case 'board_game':
        return ('🎲 BOARD GAME', Colors.purpleAccent, Icons.casino_rounded);
      default:
        return ('⚡ GIAO LƯU', Colors.greenAccent, Icons.bolt_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityId = activity['id'] as String? ?? '';
    final title = (activity['title'] as String?) ?? 'Hoạt động';
    final description = (activity['description'] as String?) ?? '';
    final location = (activity['location_name'] as String?) ?? 'Chưa có địa điểm';
    final type = (activity['type'] as String?) ?? 'treasure_hunt';
    final maxMembers = (activity['max_members'] as num?)?.toInt() ?? 5;
    final (typeTag, typeColor, typeIcon) = _typeInfo(type);

    final hostName = (activity['host_name'] as String?) ??
        (activity['creator_name'] as String?) ??
        'Thành viên';
    final hostAvatarUrl = activity['host_avatar_url'] as String?;

    final targetGender = (activity['target_gender'] as String?) ?? 'all';
    final joinPolicy = (activity['join_policy'] as String?) ?? 'everyone';

    return _FeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: hostAvatarUrl,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hostName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      typeTag,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC6CEDF),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D2C),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _genderLabel(targetGender),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D2C),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _policyLabel(joinPolicy),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D2C),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Tối đa $maxMembers người',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    if (activityId.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        '/activities/detail',
                        arguments: activityId,
                      );
                    } else {
                      Navigator.pushNamed(context, '/activities');
                    }
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Xem chi tiết hoạt động'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _LobbyCard extends StatelessWidget {
  const _LobbyCard();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🗝️  SẢNH CHỜ SIÊU TRÍ TUỆ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _FeedCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Câu đố Giải mã Cổ vật',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Cần 1 thành viên hiểu biết về lịch sử TP.HCM',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Tham gia'),
                ),
              ],
            ),
          ),
        ],
      );
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _NearbyBadge extends StatelessWidget {
  const _NearbyBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withValues(alpha: .3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_rounded, color: AppColors.cyan, size: 14),
            SizedBox(width: 4),
            Text(
              'LIVE RADAR',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

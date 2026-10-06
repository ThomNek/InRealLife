import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
  Widget build(BuildContext context) => ListView(
        controller: controller,
        physics: mobile
            ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
            : const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 12 : 0,
          mobile ? 12 : 0,
          mobile ? 12 : 0,
          96,
        ),
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
          const _FilterChips(),
          const SizedBox(height: 12),
          const _SocialPost(
            initials: 'MA',
            name: 'Minh Anh',
            hostBadge: '⭐ Cấp 2',
            meta: '15 phút trước · Cách bạn 0,8 km · Q.1, TP.HCM',
            tag: '💎 SĂN KHO BÁU',
            body: 'Mình vừa kích hoạt manh mối Kho báu Cổ Thụ. Đang mở đội đi cùng để giải câu đố tại khu vực công viên!',
            teamName: 'Biệt đội Săn Đêm',
            teamMembers: '3/4 người',
            likes: 18,
          ),
          const SizedBox(height: 12),
          const _SocialPost(
            initials: 'TV',
            name: 'Thảo Vy',
            hostBadge: '⭐ Cấp 1',
            meta: '45 phút trước · Cách bạn 1,2 km · Thư viện Thành phố',
            tag: '🏃 ĐI BỘ & GIAO LƯU',
            body: 'Đội đi bộ rèn luyện sức khỏe cuối tuần quanh khu vực Thư viện. Bạn nào rảnh tham gia ghép đội cùng nhé! 🔍',
            teamName: 'CLB Chạy & Khám Phá',
            teamMembers: '2/5 người',
            likes: 32,
            purple: true,
          ),
          const SizedBox(height: 12),
          const _AchievementPost(),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Xem thêm hoạt động gần đây'),
          ),
          const SizedBox(height: 16),
          const _LobbyCard(),
        ],
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

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Filter(label: 'Tất cả', active: true),
            _Filter(label: '💎 Săn kho báu'),
            _Filter(label: '🏃 Đi bộ'),
            _Filter(label: '👥 Đội đang mở'),
            _Filter(label: '🏆 Đã mở rương'),
          ],
        ),
      );
}

class _SocialPost extends StatelessWidget {
  const _SocialPost({
    required this.initials,
    required this.name,
    required this.hostBadge,
    required this.meta,
    required this.tag,
    required this.body,
    required this.teamName,
    required this.teamMembers,
    required this.likes,
    this.purple = false,
  });

  final String initials, name, hostBadge, meta, tag, body, teamName, teamMembers;
  final int likes;
  final bool purple;

  @override
  Widget build(BuildContext context) => _FeedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: purple
                      ? const Color(0xFF70449A)
                      : const Color(0xFF256F55),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
                            child: Text(
                              hostBadge,
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        meta,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: (purple ? const Color(0xFFC084FC) : AppColors.cyan)
                        .withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: purple ? const Color(0xFFC084FC) : AppColors.cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2435),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đội do host mở: $teamName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Sĩ số: $teamMembers',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: const Text('Xin tham gia'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                _PostAction(
                  icon: Icons.favorite_border_rounded,
                  label: '$likes',
                ),
                const _PostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Bình luận',
                ),
                const _PostAction(
                  icon: Icons.share_outlined,
                  label: 'Chia sẻ',
                ),
              ],
            ),
          ],
        ),
      );
}

class _AchievementPost extends StatelessWidget {
  const _AchievementPost();

  @override
  Widget build(BuildContext context) => _FeedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFB87920),
                  child: Text(
                    'HN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoàng Nam và 3 đồng đội',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '2 giờ trước · Bờ sông Sài Gòn · Cách bạn 2,4 km',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _PostTag(label: 'ĐÃ MỞ RƯƠNG'),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final image = ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    _bannerAsset,
                    width: double.infinity,
                    height: 132,
                    fit: BoxFit.cover,
                  ),
                );
                const copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kho báu Hoàng Hôn',
                      style: TextStyle(
                        color: Color(0xFFFFD428),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      '4 người đã gặp nhau tại điểm săn, giải mã thành công và nhận huy hiệu Co-op đầu tiên.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🏆 +500 EXP · 4 mảnh ghép',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 580) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [image, const SizedBox(height: 12), copy],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 220, child: image),
                    const SizedBox(width: 14),
                    const Expanded(child: copy),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            const Row(
              children: [
                _PostAction(
                  icon: Icons.favorite_border_rounded,
                  label: '47',
                ),
                _PostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '14 bình luận',
                ),
                _PostAction(
                  icon: Icons.share_outlined,
                  label: 'Chia sẻ',
                ),
              ],
            ),
          ],
        ),
      );
}

class _PostTag extends StatelessWidget {
  const _PostTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD428).withValues(alpha: .12),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFD428),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
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

class _Filter extends StatelessWidget {
  const _Filter({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: active,
          label: Text(label),
          onSelected: (_) {},
          selectedColor: AppColors.orange,
          labelStyle: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide(
            color: active ? AppColors.orange : AppColors.border,
          ),
          backgroundColor: AppColors.surface,
        ),
      );
}

class _PostAction extends StatelessWidget {
  const _PostAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.muted),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

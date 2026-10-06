import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_navigation_shell.dart';

class RadarPage extends StatelessWidget {
  const RadarPage({super.key});

  @override
  Widget build(BuildContext context) => MainShell(
        selectedIndex: 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Khám phá quanh bạn',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Vị trí của tôi',
                onPressed: () => _message(context, 'Đã tìm thấy vị trí của bạn.'),
                icon: const Icon(Icons.my_location_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final radar = const _RadarPanel();
          final nearby = const _NearbyTreasures();
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 24 : 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Header(),
                    const SizedBox(height: 16),
                    if (wide)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _RadarPanel()),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: _NearbyTreasures()),
                        ],
                      )
                    else ...[
                      radar,
                      const SizedBox(height: 16),
                      nearby,
                    ],
                    const SizedBox(height: 16),
                    const _HintCard(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  ),
);

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: const Row(
      children: [
        _IconBox(icon: Icons.radar_rounded, color: AppColors.cyan),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '4 hoạt động quanh bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Khu vực: Công viên Trung tâm · bán kính 5 km',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RadarPanel extends StatelessWidget {
  const _RadarPanel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('QUÉT KHO BÁU', style: _titleStyle),
            _LiveBadge(),
          ],
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 1.3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const CustomPaint(
              painter: _RadarPainter(),
              child: Center(
                child: _Pulse(
                  child: Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _Legend(color: Color(0xFFFFD400), label: 'Legendary'),
            _Legend(color: Color(0xFFB817F4), label: 'Epic'),
            _Legend(color: Color(0xFF00E98B), label: 'Rare'),
            _Legend(color: Colors.white, label: 'Common'),
          ],
        ),
      ],
    ),
  );
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF111722),
    );
    final grid = Paint()
      ..color = AppColors.cyan.withValues(alpha: .08)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .4;
    final ring = Paint()
      ..color = AppColors.cyan.withValues(alpha: .45)
      ..style = PaintingStyle.stroke;
    for (final scale in [.38, .7, 1.0]) {
      canvas.drawCircle(center, radius * scale, ring);
    }
    final sweep = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0,
        math.pi / 2,
        false,
      )
      ..close();
    canvas.drawPath(
      sweep,
      Paint()..color = AppColors.cyan.withValues(alpha: .2),
    );
    _dot(
      canvas,
      center + Offset(-radius * .62, -radius * .42),
      const Color(0xFFFFD400),
    );
    _dot(
      canvas,
      center + Offset(radius * .62, -radius * .48),
      const Color(0xFFB817F4),
    );
    _dot(
      canvas,
      center + Offset(radius * .1, radius * .55),
      const Color(0xFF00E98B),
    );
    _dot(canvas, center + Offset(radius * .75, radius * .35), Colors.white);
  }

  void _dot(Canvas canvas, Offset point, Color color) {
    canvas.drawCircle(point, 13, Paint()..color = color.withValues(alpha: .14));
    canvas.drawCircle(point, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Pulse extends StatelessWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppColors.orange,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.orange.withValues(alpha: .35),
          blurRadius: 22,
          spreadRadius: 5,
        ),
      ],
    ),
    child: child,
  );
}

class _NearbyTreasures extends StatelessWidget {
  const _NearbyTreasures();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOẠT ĐỘNG GẦN NHẤT', style: _titleStyle),
        SizedBox(height: 12),
        _TreasureTile(
          color: Color(0xFF00E98B),
          title: 'Mảnh ghép B7',
          place: 'Vườn hoa phía Đông',
          distance: '320 m',
        ),
        Divider(height: 26),
        _TreasureTile(
          color: Color(0xFFFFD400),
          title: 'Rương Hoàng Hôn',
          place: 'Gần tháp đồng hồ',
          distance: '850 m',
        ),
        Divider(height: 26),
        _TreasureTile(
          color: Color(0xFFB817F4),
          title: 'Manh mối bí ẩn',
          place: 'Thư viện Thành phố',
          distance: '1,2 km',
        ),
        Divider(height: 26),
        _TreasureTile(
          color: Colors.white,
          title: 'Điểm hẹn đồng đội',
          place: 'Cổng công viên',
          distance: '1,8 km',
        ),
      ],
    ),
  );
}

class _TreasureTile extends StatelessWidget {
  const _TreasureTile({
    required this.color,
    required this.title,
    required this.place,
    required this.distance,
  });
  final Color color;
  final String title;
  final String place;
  final String distance;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.location_on_rounded, color: color),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
              place,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Text(
        distance,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _decoration(border: const Color(0xFF66521A)),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBox(icon: Icons.lightbulb_rounded, color: Color(0xFFFFD400)),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MẸO RADAR', style: _titleStyle),
              SizedBox(height: 6),
              Text(
                'Di chuyển ngoài đời thật để cập nhật tín hiệu. Kho báu càng gần, điểm sáng trên radar càng rõ.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.greenAccent.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      '● TRỰC TIẾP',
      style: TextStyle(
        color: Colors.greenAccent,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}

const _titleStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
  letterSpacing: .6,
);

BoxDecoration _decoration({Color border = AppColors.border}) => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: border),
);

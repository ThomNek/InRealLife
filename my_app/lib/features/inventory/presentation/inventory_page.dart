import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_navigation_shell.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late int _tab = widget.initialTab;

  static const _tabs = [
    ('Tất cả', Icons.shopping_bag_outlined, '12'),
    ('Mảnh ghép', Icons.extension_outlined, '8'),
    ('Trao đổi', Icons.swap_horiz_rounded, '2'),
    ('Lịch sử', Icons.history_rounded, ''),
  ];

  @override
  Widget build(BuildContext context) => MainShell(
        selectedIndex: 3,
        child: Scaffold(
    appBar: AppBar(
      title: const Text(
        'TREASURE IRL',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: 'Hồ sơ',
          onPressed: () => Navigator.pushNamed(context, '/profile'),
          icon: const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFF153847),
            child: Text(
              'AN',
              style: TextStyle(color: AppColors.cyan, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              wide ? 28 : 14,
              20,
              wide ? 28 : 14,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Quay lại trang chủ'),
                    ),
                    const SizedBox(height: 24),
                    _PageHeading(wide: wide),
                    const SizedBox(height: 22),
                    _TabBar(
                      tabs: _tabs,
                      selected: _tab,
                      onSelected: (value) => setState(() => _tab = value),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 22),
                    if (_tab == 2)
                      const _MarketView()
                    else if (_tab == 3)
                      const _HistoryView()
                    else ...[
                      const _SetCard(),
                      const SizedBox(height: 18),
                      if (wide)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _Collection()),
                            SizedBox(width: 18),
                            Expanded(flex: 2, child: _Offers()),
                          ],
                        )
                      else ...[
                        const _Collection(),
                        const SizedBox(height: 18),
                        const _Offers(),
                      ],
                    ],
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
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    const intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KHO CỦA ALEXNGUYEN', style: _eyebrow),
        SizedBox(height: 10),
        Text(
          'Vật phẩm & Mảnh ghép',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8),
        Text(
          'Quản lý bộ sưu tập, tìm mảnh còn thiếu và trao đổi với thợ săn khác.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ],
    );
    const summary = Row(
      children: [
        Expanded(
          child: _Summary(value: '12', label: 'Mảnh sở hữu'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _Summary(value: '4', label: 'Có thể đổi'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _Summary(value: '3', label: 'Bộ đang ghép'),
        ),
      ],
    );
    return wide
        ? const Row(
            children: [
              Expanded(child: intro),
              SizedBox(width: 30),
              SizedBox(width: 430, child: summary),
            ],
          )
        : const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [intro, SizedBox(height: 20), summary],
          );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });
  final List<(String, IconData, String)> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(tabs.length, (index) {
        final item = tabs[index];
        final active = selected == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () => onSelected(index),
            icon: Icon(
              item.$2,
              color: active ? AppColors.cyan : AppColors.muted,
            ),
            label: Text('${item.$1}${item.$3.isEmpty ? '' : '  ${item.$3}'}'),
            style: TextButton.styleFrom(
              foregroundColor: active ? AppColors.cyan : AppColors.muted,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            ),
          ),
        );
      }),
    ),
  );
}

class _SetCard extends StatelessWidget {
  const _SetCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LEGENDARY SET', style: _eyebrow),
                  SizedBox(height: 8),
                  Text(
                    'Bộ Kho báu Hoàng Hôn',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Hoàn thiện bộ để tham gia mật mã cuối tại Bờ sông Sài Gòn.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '75%',
                  style: TextStyle(
                    color: Color(0xFFFFD400),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('3/4 mảnh', style: TextStyle(color: AppColors.muted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            value: .75,
            minHeight: 10,
            backgroundColor: Color(0xFF31354A),
            valueColor: AlwaysStoppedAnimation(Color(0xFFFFA000)),
          ),
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Piece(
              code: 'A3',
              note: 'Mảnh chính',
              icon: Icons.lock_outline_rounded,
            ),
            _Piece(
              code: 'C2',
              note: 'Có mảnh dư',
              icon: Icons.extension_rounded,
            ),
            _Piece(
              code: 'D5',
              note: 'Mảnh chính',
              icon: Icons.lock_outline_rounded,
            ),
            _Piece(
              code: 'B7',
              note: 'Đang thiếu',
              icon: Icons.search_rounded,
              missing: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171B29),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFFFD400)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Còn thiếu mảnh B7\n6 thợ săn gần bạn đang sở hữu',
                  style: TextStyle(height: 1.45),
                ),
              ),
              FilledButton(onPressed: () {}, child: const Text('Tìm B7')),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Piece extends StatelessWidget {
  const _Piece({
    required this.code,
    required this.note,
    required this.icon,
    this.missing = false,
  });
  final String code;
  final String note;
  final IconData icon;
  final bool missing;
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: missing ? Colors.transparent : const Color(0xFF292C3C),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: missing ? AppColors.muted : AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, color: missing ? AppColors.muted : const Color(0xFFFFD400)),
        const SizedBox(height: 7),
        Text(
          code,
          style: TextStyle(
            color: missing ? AppColors.muted : const Color(0xFFFFD400),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          note,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _Collection extends StatelessWidget {
  const _Collection();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BỘ SƯU TẬP', style: _eyebrow),
        const SizedBox(height: 6),
        const Text(
          'Tất cả mảnh ghép',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Tìm mã mảnh hoặc bộ...',
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _Item(code: 'A3', set: 'Hoàng Hôn', color: Color(0xFFFFD400)),
            _Item(code: 'C2 ×2', set: 'Hoàng Hôn', color: Color(0xFFFFD400)),
            _Item(code: 'K4', set: 'Thư Viện', color: Color(0xFFB817F4)),
            _Item(code: 'R2', set: 'Cổ Thụ', color: Color(0xFF00E98B)),
          ],
        ),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item({required this.code, required this.set, required this.color});
  final String code;
  final String set;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF191D2B),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.extension_rounded, color: color),
        const SizedBox(height: 6),
        Text(
          code,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        Text(
          'Bộ $set',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _Offers extends StatelessWidget {
  const _Offers();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CHỢ MẢNH GHÉP', style: _eyebrow),
        SizedBox(height: 6),
        Text(
          'Gợi ý trao đổi',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 12),
        _Offer(name: 'Hoàng Nam', initials: 'HN', give: 'C2', receive: 'B7'),
        SizedBox(height: 10),
        _Offer(name: 'Thảo Vy', initials: 'TV', give: 'K4', receive: 'B7'),
        SizedBox(height: 16),
        _SafeTrade(),
      ],
    ),
  );
}

class _MarketView extends StatelessWidget {
  const _MarketView();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Chợ Mảnh ghép',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      SizedBox(height: 6),
      Text(
        'Các đề nghị phù hợp với những mảnh bạn đang có.',
        style: TextStyle(color: AppColors.muted),
      ),
      SizedBox(height: 18),
      _Offers(),
    ],
  );
}

class _Offer extends StatelessWidget {
  const _Offer({
    required this.name,
    required this.initials,
    required this.give,
    required this.receive,
  });
  final String name;
  final String initials;
  final String give;
  final String receive;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFF191D2B),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF078CA0),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppColors.cyan, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TradeValue(label: 'BẠN ĐƯA', value: give),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.swap_horiz_rounded, color: AppColors.cyan),
            ),
            Expanded(
              child: _TradeValue(label: 'BẠN NHẬN', value: receive),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: null, child: Text('Xem đề nghị')),
        ),
      ],
    ),
  );
}

class _TradeValue extends StatelessWidget {
  const _TradeValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD400),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _SafeTrade extends StatelessWidget {
  const _SafeTrade();
  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.shield_outlined, color: Colors.greenAccent),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          'Trao đổi an toàn\nChỉ gặp ở nơi công cộng và cùng xác nhận vật phẩm.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ),
    ],
  );
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử vật phẩm',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 18),
        ListTile(
          leading: Icon(Icons.add_circle_outline, color: Colors.greenAccent),
          title: Text('Nhận mảnh C2'),
          subtitle: Text('Rương Thư Viện · Hôm qua'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.swap_horiz_rounded, color: AppColors.cyan),
          title: Text('Đổi A1 lấy K4'),
          subtitle: Text('Với MinhLee · 3 ngày trước'),
        ),
      ],
    ),
  );
}

const _eyebrow = TextStyle(
  color: AppColors.cyan,
  fontWeight: FontWeight.w900,
  letterSpacing: .8,
  fontSize: 12,
);

BoxDecoration _decoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);

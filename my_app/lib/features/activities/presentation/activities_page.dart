import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/activity_explore_card.dart';
import 'widgets/activity_filter_modal.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  ActivityFilterState _filterState = const ActivityFilterState();

  static const _categoryFilters = [
    {'label': 'Tất cả', 'value': 'all'},
    {'label': 'Kho báu', 'value': 'treasure_hunt'},
    {'label': 'Đi bộ', 'value': 'walking'},
    {'label': 'Thể thao', 'value': 'sport'},
    {'label': 'Cà phê', 'value': 'coffee'},
  ];

  static final List<Map<String, dynamic>> _exploreItems = [
    {
      'id': 'ACT-01',
      'icon': Icons.explore_rounded,
      'color': AppColors.cyan,
      'title': 'Kho báu Hoàng Hôn',
      'type': 'treasure_hunt',
      'typeLabel': 'SĂN KHO BÁU · ĐI BỘ',
      'meta': 'Thứ Bảy, 17:30 · 1,2 km',
      'distance_km': 1.2,
      'people': '3/5 người',
      'level': 'Mới bắt đầu',
      'route': '/activities/sunset',
    },
    {
      'id': 'ACT-02',
      'icon': Icons.sports_tennis_rounded,
      'color': const Color(0xFFFFD22E),
      'title': 'Cầu lông thử thách',
      'type': 'sport',
      'typeLabel': 'THỂ THAO · HỢP TÁC',
      'meta': 'Thứ Bảy, 18:00 · 2,4 km',
      'distance_km': 2.4,
      'people': '3/4 người',
      'level': 'Cơ bản',
      'route': null,
    },
    {
      'id': 'ACT-03',
      'icon': Icons.local_cafe_outlined,
      'color': AppColors.orange,
      'title': 'Cà phê & câu đố',
      'type': 'coffee',
      'typeLabel': 'GIAO LƯU · NHÓM NHỎ',
      'meta': 'Chủ Nhật, 09:00 · 800 m',
      'distance_km': 0.8,
      'people': '2/6 người',
      'level': 'Mọi trình độ',
      'route': null,
    },
    {
      'id': 'ACT-04',
      'icon': Icons.directions_run_rounded,
      'color': Colors.greenAccent,
      'title': 'Chạy qua 4 dấu mốc',
      'type': 'walking',
      'typeLabel': 'CHẠY BỘ · GIẢI MÃ',
      'meta': 'Chủ Nhật, 06:30 · 3,1 km',
      'distance_km': 3.1,
      'people': '4/8 người',
      'level': 'Trung bình',
      'route': null,
    },
  ];

  Future<void> _openFilterModal() async {
    final result = await showActivityFilterModal(context, _filterState);
    if (result != null && mounted) {
      setState(() => _filterState = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filterState.filterList(_exploreItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hoạt động',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _openFilterModal,
            icon: _filterState.isFiltered
                ? Badge(
                    label: Text('${_filterState.activeCount}'),
                    child: const Icon(Icons.tune_rounded),
                  )
                : const Icon(Icons.tune_rounded),
            tooltip: 'Bộ lọc',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 3
                : constraints.maxWidth >= 680
                    ? 2
                    : 1;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tìm một lý do để bước ra ngoài',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Hoạt động nhóm nhỏ, địa điểm công cộng và mục tiêu rõ ràng.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              onChanged: (val) {
                                setState(() {
                                  _filterState =
                                      _filterState.copyWith(searchQuery: val);
                                });
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search_rounded),
                                hintText:
                                    'Tìm hoạt động, địa điểm hoặc sở thích...',
                              ),
                            ),
                            const SizedBox(height: 13),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  _categoryFilters.length,
                                  (index) {
                                    final cat = _categoryFilters[index];
                                    final selected =
                                        _filterState.type == cat['value'];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        selected: selected,
                                        onSelected: (_) {
                                          setState(() {
                                            _filterState = _filterState.copyWith(
                                              type: cat['value']!,
                                            );
                                          });
                                        },
                                        label: Text(cat['label']!),
                                        showCheckmark: false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.cyan,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _filterState.maxDistanceKm >= 50.0
                                      ? 'Tất cả khoảng cách · Cuối tuần này'
                                      : 'Trong bán kính ${_filterState.maxDistanceKm.toStringAsFixed(0)} km · Cuối tuần này',
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                            if (_filterState.isFiltered) ...[
                              const SizedBox(height: 8),
                              ActivityFilterSummaryBar(
                                filterState: _filterState,
                                onReset: () => setState(
                                  () => _filterState = const ActivityFilterState(),
                                ),
                                onOpenFilter: _openFilterModal,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  sliver: SliverLayoutBuilder(
                    builder: (context, size) {
                      const gap = 14.0;
                      if (filteredItems.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Không tìm thấy hoạt động nào phù hợp với bộ lọc.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          mainAxisExtent: columns == 1 ? 270 : 310,
                        ),
                        delegate: SliverChildListDelegate(
                          filteredItems.map((item) {
                            return ActivityExploreCard(
                              icon: item['icon'] as IconData,
                              color: item['color'] as Color,
                              title: item['title'] as String,
                              type: item['typeLabel'] as String,
                              meta: item['meta'] as String,
                              people: item['people'] as String,
                              level: item['level'] as String,
                              onTap: () {
                                final route = item['route'] as String?;
                                if (route != null) {
                                  Navigator.pushNamed(context, route);
                                } else {
                                  _soon(context);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/activities/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo hoạt động'),
      ),
    );
  }

  static void _soon(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(
        const SnackBar(
          content: Text('Chi tiết hoạt động này sẽ được bổ sung sau.'),
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// State của bộ lọc hoạt động & đội nhóm.
class ActivityFilterState {
  const ActivityFilterState({
    this.maxDistanceKm = 10.0,
    this.type = 'all',
    this.status = 'all',
    this.skillLevel = 'all',
    this.gender = 'all',
    this.joinPolicy = 'all',
    this.searchQuery = '',
  });

  final double maxDistanceKm; // 1.0, 3.0, 5.0, 10.0, 20.0, 50.0 (50 = Không giới hạn)
  final String type; // all, treasure_hunt, walking, sport, coffee, board_game
  final String status; // all, open, full
  final String skillLevel; // all, beginner, basic, intermediate, advanced
  final String gender; // all, male_only, female_only
  final String joinPolicy; // all, everyone, friends_only
  final String searchQuery;

  bool get isFiltered =>
      maxDistanceKm < 50.0 ||
      type != 'all' ||
      status != 'all' ||
      skillLevel != 'all' ||
      gender != 'all' ||
      joinPolicy != 'all' ||
      searchQuery.isNotEmpty;

  int get activeCount {
    int count = 0;
    if (maxDistanceKm < 50.0) count++;
    if (type != 'all') count++;
    if (status != 'all') count++;
    if (skillLevel != 'all') count++;
    if (gender != 'all') count++;
    if (joinPolicy != 'all') count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  ActivityFilterState copyWith({
    double? maxDistanceKm,
    String? type,
    String? status,
    String? skillLevel,
    String? gender,
    String? joinPolicy,
    String? searchQuery,
  }) {
    return ActivityFilterState(
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      type: type ?? this.type,
      status: status ?? this.status,
      skillLevel: skillLevel ?? this.skillLevel,
      gender: gender ?? this.gender,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Lọc một danh sách các map item (hoạt động hoặc đội nhóm)
  List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> items) {
    return items.where((item) {
      // 1. Lọc theo tìm kiếm từ khóa
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
        final location = (item['location_name'] ?? item['meeting_area'] ?? '').toString().toLowerCase();
        final desc = (item['description'] ?? '').toString().toLowerCase();
        if (!title.contains(query) && !location.contains(query) && !desc.contains(query)) {
          return false;
        }
      }

      // 2. Lọc theo Khoảng cách (distance_km)
      if (maxDistanceKm < 50.0) {
        final rawDist = item['distance_km'] ?? item['distance'];
        double dist = 1.2;
        if (rawDist is num) {
          dist = rawDist.toDouble();
        } else if (rawDist is String) {
          dist = double.tryParse(rawDist.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.2;
        }
        if (dist > maxDistanceKm) return false;
      }

      // 3. Lọc theo loại hoạt động
      if (type != 'all') {
        final itemType = (item['type'] ?? item['activity_type'] ?? '').toString();
        if (itemType != type) return false;
      }

      // 4. Lọc theo trạng thái
      if (status != 'all') {
        final itemStatus = (item['status'] ?? '').toString();
        if (itemStatus != status) return false;
      }

      // 5. Lọc theo trình độ
      if (skillLevel != 'all') {
        final itemLevel = (item['skill_level'] ?? '').toString();
        if (itemLevel != skillLevel) return false;
      }

      // 6. Lọc theo giới tính mục tiêu
      if (gender != 'all') {
        final itemGender = (item['target_gender'] ?? '').toString();
        if (itemGender != gender && itemGender.isNotEmpty) return false;
      }

      // 7. Lọc theo quyền gia nhập (join_policy)
      if (joinPolicy != 'all') {
        final itemPolicy = (item['join_policy'] ?? '').toString();
        if (itemPolicy.isNotEmpty && itemPolicy != joinPolicy) return false;
      }

      return true;
    }).toList();
  }
}

/// Mở BottomSheet bộ lọc
Future<ActivityFilterState?> showActivityFilterModal(
  BuildContext context,
  ActivityFilterState initialState,
) {
  return showModalBottomSheet<ActivityFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ActivityFilterSheet(initialState: initialState),
  );
}

class _ActivityFilterSheet extends StatefulWidget {
  const _ActivityFilterSheet({required this.initialState});
  final ActivityFilterState initialState;

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  late ActivityFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.cyan),
              const SizedBox(width: 8),
              const Text(
                'Bộ lọc hoạt động',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (_state.isFiltered)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _state = const ActivityFilterState();
                    });
                  },
                  child: const Text('Đặt lại'),
                ),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Khoảng cách (Bán kính)
                  _SectionTitle(
                    title: 'Bán kính khoảng cách',
                    subtitle: _state.maxDistanceKm >= 50.0
                        ? 'Tất cả khoảng cách'
                        : 'Trong vòng ${_state.maxDistanceKm.toStringAsFixed(0)} km',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: '< 1 km',
                        selected: _state.maxDistanceKm == 1.0,
                        onSelected: () => setState(() => _state = _state.copyWith(maxDistanceKm: 1.0)),
                      ),
                      _FilterChoiceChip(
                        label: '< 3 km',
                        selected: _state.maxDistanceKm == 3.0,
                        onSelected: () => setState(() => _state = _state.copyWith(maxDistanceKm: 3.0)),
                      ),
                      _FilterChoiceChip(
                        label: '< 5 km',
                        selected: _state.maxDistanceKm == 5.0,
                        onSelected: () => setState(() => _state = _state.copyWith(maxDistanceKm: 5.0)),
                      ),
                      _FilterChoiceChip(
                        label: '< 10 km',
                        selected: _state.maxDistanceKm == 10.0,
                        onSelected: () => setState(() => _state = _state.copyWith(maxDistanceKm: 10.0)),
                      ),
                      _FilterChoiceChip(
                        label: '< 20 km',
                        selected: _state.maxDistanceKm == 20.0,
                        onSelected: () => setState(() => _state = _state.copyWith(maxDistanceKm: 20.0)),
                      ),
                      _FilterChoiceChip(
                        label: 'Tất cả',
                        selected: _state.maxDistanceKm >= 50.0,
                        onSelected: () => setState(() => _state = _state.copyWith(maxDistanceKm: 50.0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Loại hoạt động
                  const _SectionTitle(title: 'Loại hoạt động'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'Tất cả',
                        selected: _state.type == 'all',
                        onSelected: () => setState(() => _state = _state.copyWith(type: 'all')),
                      ),
                      _FilterChoiceChip(
                        label: '💎 Săn kho báu',
                        selected: _state.type == 'treasure_hunt',
                        onSelected: () => setState(() => _state = _state.copyWith(type: 'treasure_hunt')),
                      ),
                      _FilterChoiceChip(
                        label: '🏃 Đi bộ',
                        selected: _state.type == 'walking',
                        onSelected: () => setState(() => _state = _state.copyWith(type: 'walking')),
                      ),
                      _FilterChoiceChip(
                        label: '🎾 Thể thao',
                        selected: _state.type == 'sport',
                        onSelected: () => setState(() => _state = _state.copyWith(type: 'sport')),
                      ),
                      _FilterChoiceChip(
                        label: '☕ Cà phê câu đố',
                        selected: _state.type == 'coffee',
                        onSelected: () => setState(() => _state = _state.copyWith(type: 'coffee')),
                      ),
                      _FilterChoiceChip(
                        label: '🎲 Board game',
                        selected: _state.type == 'board_game',
                        onSelected: () => setState(() => _state = _state.copyWith(type: 'board_game')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Trạng thái
                  const _SectionTitle(title: 'Trạng thái'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'Tất cả',
                        selected: _state.status == 'all',
                        onSelected: () => setState(() => _state = _state.copyWith(status: 'all')),
                      ),
                      _FilterChoiceChip(
                        label: '🟢 Đang mở',
                        selected: _state.status == 'open',
                        onSelected: () => setState(() => _state = _state.copyWith(status: 'open')),
                      ),
                      _FilterChoiceChip(
                        label: '🔴 Đã đầy',
                        selected: _state.status == 'full',
                        onSelected: () => setState(() => _state = _state.copyWith(status: 'full')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Đối tượng tham gia
                  const _SectionTitle(title: 'Giới tính mục tiêu'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'Tất cả',
                        selected: _state.gender == 'all',
                        onSelected: () => setState(() => _state = _state.copyWith(gender: 'all')),
                      ),
                      _FilterChoiceChip(
                        label: '👩 Chỉ nữ',
                        selected: _state.gender == 'female_only',
                        onSelected: () => setState(() => _state = _state.copyWith(gender: 'female_only')),
                      ),
                      _FilterChoiceChip(
                        label: '👨 Chỉ nam',
                        selected: _state.gender == 'male_only',
                        onSelected: () => setState(() => _state = _state.copyWith(gender: 'male_only')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Quyền gia nhập (Ai có thể tham gia)
                  const _SectionTitle(title: 'Quyền gia nhập (Ai có thể tham gia)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChoiceChip(
                        label: 'Tất cả',
                        selected: _state.joinPolicy == 'all',
                        onSelected: () => setState(() => _state = _state.copyWith(joinPolicy: 'all')),
                      ),
                      _FilterChoiceChip(
                        label: '🌐 Mọi người',
                        selected: _state.joinPolicy == 'everyone',
                        onSelected: () => setState(() => _state = _state.copyWith(joinPolicy: 'everyone')),
                      ),
                      _FilterChoiceChip(
                        label: '🤝 Chỉ bạn bè',
                        selected: _state.joinPolicy == 'friends_only',
                        onSelected: () => setState(() => _state = _state.copyWith(joinPolicy: 'friends_only')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context, _state),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(
              _state.isFiltered
                  ? 'Áp dụng bộ lọc (${_state.activeCount})'
                  : 'Áp dụng bộ lọc',
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

/// Thanh hiển thị các chip bộ lọc đang hoạt động
class ActivityFilterSummaryBar extends StatelessWidget {
  const ActivityFilterSummaryBar({
    super.key,
    required this.filterState,
    required this.onReset,
    required this.onOpenFilter,
  });

  final ActivityFilterState filterState;
  final VoidCallback onReset;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    if (!filterState.isFiltered) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (filterState.maxDistanceKm < 50.0) {
      chips.add(_ChipItem(label: '📍 < ${filterState.maxDistanceKm.toStringAsFixed(0)} km'));
    }
    if (filterState.type != 'all') {
      chips.add(_ChipItem(label: _typeLabel(filterState.type)));
    }
    if (filterState.status != 'all') {
      chips.add(_ChipItem(label: filterState.status == 'open' ? '🟢 Đang mở' : '🔴 Đã đầy'));
    }
    if (filterState.gender != 'all') {
      chips.add(_ChipItem(label: filterState.gender == 'female_only' ? '👩 Chỉ nữ' : '👨 Chỉ nam'));
    }
    if (filterState.joinPolicy != 'all') {
      chips.add(_ChipItem(label: filterState.joinPolicy == 'friends_only' ? '🤝 Chỉ bạn bè' : '🌐 Mọi người'));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 8),
                  for (final chip in chips) ...[
                    chip,
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onReset,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'treasure_hunt':
        return '💎 Săn kho báu';
      case 'walking':
        return '🏃 Đi bộ';
      case 'sport':
        return '🎾 Thể thao';
      case 'coffee':
        return '☕ Cà phê';
      case 'board_game':
        return '🎲 Board game';
      default:
        return type;
    }
  }
}

class _ChipItem extends StatelessWidget {
  const _ChipItem({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

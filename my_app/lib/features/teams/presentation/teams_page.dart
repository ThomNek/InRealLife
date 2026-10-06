import 'package:flutter/material.dart';

import '../../activities/presentation/participation_page.dart';

/// Tên tương thích cho các chỗ cũ từng mở màn hình đội riêng.
///
/// Hoạt động và đội hiện được quản lý trong cùng [ParticipationPage] để tránh
/// hai màn hình tải hai nguồn dữ liệu khác nhau. Route mới nên dùng trực tiếp
/// `ParticipationPage`; lớp này được giữ lại để import cũ không bị lỗi.
@Deprecated('Use ParticipationPage instead.')
class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) => const ParticipationPage();
}

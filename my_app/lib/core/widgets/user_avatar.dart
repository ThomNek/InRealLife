import 'package:flutter/material.dart';

/// Avatar dùng chung cho các khu vực tài khoản.
///
/// Ảnh cục bộ luôn được dùng trong lúc tải và khi URL lỗi, nhờ đó kết nối ảnh
/// chậm không làm mất avatar hoặc tạo vùng trống trên giao diện.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.fallbackAsset,
    this.avatarUrl,
    this.radius = 20,
    this.backgroundColor = Colors.white,
  });

  final String fallbackAsset;
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = avatarUrl?.trim();
    final fallback = Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: normalizedUrl?.isNotEmpty == true
            ? Image.network(
                normalizedUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

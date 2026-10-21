import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Nút Back tùy chỉnh dùng chung cho toàn bộ ứng dụng.
///
/// Tương thích với thanh điều hướng (AppBar / SliverAppBar), hỗ trợ:
/// - Icon quay lại mượt mà với hiệu ứng hover/tap chuẩn.
/// - Huy hiệu (badge) cảnh báo khi có thay đổi chưa lưu (`hasBadge` / `badgeColor`).
/// - Custom callback `onPressed` hoặc tự động gọi `Navigator.maybePop(context)`.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.hasBadge = false,
    this.badgeColor = AppColors.orange,
    this.tooltip,
    this.icon = Icons.arrow_back_rounded,
    this.color,
  });

  /// Hành động khi bấm nút. Nếu null sẽ mặc định pop Navigator.
  final VoidCallback? onPressed;

  /// Hiển thị chấm tròn cảnh báo (ví dụ: form có thay đổi chưa lưu).
  final bool hasBadge;

  /// Màu của dấu chấm cảnh báo (mặc định là cam thương hiệu).
  final Color badgeColor;

  /// Chú thích hiển thị khi hover hoặc long-press.
  final String? tooltip;

  /// Icon mũi tên (mặc định là arrow_back_rounded).
  final IconData icon;

  /// Màu của icon.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveTooltip = tooltip ??
        (hasBadge ? 'Có thay đổi chưa lưu' : MaterialLocalizations.of(context).backButtonTooltip);

    return IconButton(
      tooltip: effectiveTooltip,
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color),
          if (hasBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: .5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Đường dẫn ảnh đại diện mặc định theo giới tính.
///
/// Ảnh được lưu tại `assets/images/avatars/` để dễ thay thế
/// mà không cần rebuild khi dùng CDN sau này.
class AvatarDefaults {
  AvatarDefaults._();

  static const String male = 'assets/images/avatars/avatar_male.png';
  static const String female = 'assets/images/avatars/avatar_female.png';
  static const String other = 'assets/images/avatars/avatar_male.png';
  static const String fallbackLogo = 'assets/images/avatars/avatar_male.png';

  /// Trả về asset path phù hợp với giới tính. Nếu gender null/không khớp → mặc định avatar_male.
  static String forGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'female':
        return female;
      case 'male':
      default:
        return male;
    }
  }
}

/// Avatar dùng chung cho các khu vực tài khoản.
///
/// - Nếu `avatarUrl` có giá trị → dùng ảnh mạng (với fallback ảnh local).
/// - Nếu không có URL → hiển thị ảnh mặc định theo `gender`.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    @Deprecated('Dùng gender thay vì truyền fallbackAsset cụ thể')
    this.fallbackAsset,
    this.avatarUrl,
    this.gender,
    this.radius = 20,
    this.backgroundColor = Colors.white,
  });

  // ignore: deprecated_member_use_from_same_package
  final String? fallbackAsset;
  final String? avatarUrl;
  final String? gender;
  final double radius;
  final Color backgroundColor;

  String get _resolvedFallback {
    // ignore: deprecated_member_use_from_same_package
    if (fallbackAsset != null) return fallbackAsset!;
    return AvatarDefaults.forGender(gender);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = avatarUrl?.trim();
    final fallbackWidget = Image.asset(
      _resolvedFallback,
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
      // Nếu file avatar_*.png chưa có sẽ fallback Logo
      errorBuilder: (_, _, _) => Image.asset(
        AvatarDefaults.fallbackLogo,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
      ),
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
                    progress == null ? child : fallbackWidget,
                errorBuilder: (_, _, _) => fallbackWidget,
              )
            : fallbackWidget,
      ),
    );
  }
}

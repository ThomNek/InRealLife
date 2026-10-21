class FriendItem {
  const FriendItem({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.city = '',
    this.status = 'accepted',
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String city;
  final String status;

  factory FriendItem.fromMap(Map<String, dynamic> map) {
    return FriendItem(
      id: map['id'] as String? ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'Bạn bè',
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String? ?? '',
      status: map['status'] as String? ?? 'accepted',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'city': city,
      'status': status,
    };
  }
}

class FriendRequestItem {
  const FriendRequestItem({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.city = '',
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String city;
  final DateTime? createdAt;

  factory FriendRequestItem.fromMap(Map<String, dynamic> map) {
    final rawCreated = map['created_at'] as String?;
    return FriendRequestItem(
      id: map['id'] as String? ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'Người dùng',
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String? ?? '',
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'city': city,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

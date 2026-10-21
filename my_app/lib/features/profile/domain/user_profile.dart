class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.bio = '',
    this.city = '',
    this.district = '',
    this.interests = const [],
    this.birthYear,
    this.birthDate,
    this.gender = 'other',
    this.profileVisibility = 'public',
    this.showAge = true,
    this.showLocation = true,
    this.allowFriendRequests = true,
    this.level = 1,
    this.exp = 0,
    this.openedTreasuresCount = 0,
    this.totalDistanceKm = 0.0,
    this.exploredPlacesCount = 0,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String bio;
  final String city;
  final String district;
  final List<String> interests;
  final int? birthYear;
  final String? birthDate;
  final String gender;
  final String profileVisibility;
  final bool showAge;
  final bool showLocation;
  final bool allowFriendRequests;
  final int level;
  final int exp;
  final int openedTreasuresCount;
  final double totalDistanceKm;
  final int exploredPlacesCount;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'Người dùng',
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String? ?? '',
      city: map['city'] as String? ?? '',
      district: map['district'] as String? ?? '',
      interests: (map['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      birthYear: (map['birth_year'] as num?)?.toInt(),
      birthDate: map['birth_date'] as String?,
      gender: map['gender'] as String? ?? 'other',
      profileVisibility: map['profile_visibility'] as String? ?? 'public',
      showAge: map['show_age'] as bool? ?? true,
      showLocation: map['show_location'] as bool? ?? true,
      allowFriendRequests: map['allow_friend_requests'] as bool? ?? true,
      level: (map['level'] as num?)?.toInt() ?? 1,
      exp: (map['exp'] as num?)?.toInt() ?? 0,
      openedTreasuresCount: (map['opened_treasures_count'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (map['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      exploredPlacesCount:
          (map['explored_places_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'city': city,
      'district': district,
      'interests': interests,
      'birth_year': birthYear,
      'birth_date': birthDate,
      'gender': gender,
      'profile_visibility': profileVisibility,
      'show_age': showAge,
      'show_location': showLocation,
      'allow_friend_requests': allowFriendRequests,
      'level': level,
      'exp': exp,
      'opened_treasures_count': openedTreasuresCount,
      'total_distance_km': totalDistanceKm,
      'explored_places_count': exploredPlacesCount,
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? city,
    String? district,
    List<String>? interests,
    int? birthYear,
    String? birthDate,
    String? gender,
    String? profileVisibility,
    bool? showAge,
    bool? showLocation,
    bool? allowFriendRequests,
    int? level,
    int? exp,
    int? openedTreasuresCount,
    double? totalDistanceKm,
    int? exploredPlacesCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      district: district ?? this.district,
      interests: interests ?? this.interests,
      birthYear: birthYear ?? this.birthYear,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showAge: showAge ?? this.showAge,
      showLocation: showLocation ?? this.showLocation,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      openedTreasuresCount: openedTreasuresCount ?? this.openedTreasuresCount,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      exploredPlacesCount: exploredPlacesCount ?? this.exploredPlacesCount,
    );
  }
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    this.creatorId,
    this.hostName,
    this.hostAvatarUrl,
    required this.title,
    required this.description,
    required this.type,
    required this.locationName,
    required this.maxMembers,
    required this.startsAt,
    this.skillLevel = 'all',
    this.preparationNotes = '',
    this.targetGender = 'all',
    this.joinPolicy = 'everyone',
    this.distanceKm,
    this.status = 'open',
    this.isPublic = true,
  });

  final String id;
  final String? creatorId;
  final String? hostName;
  final String? hostAvatarUrl;
  final String title;
  final String description;
  final String type;
  final String locationName;
  final int maxMembers;
  final DateTime startsAt;
  final String skillLevel;
  final String preparationNotes;
  final String targetGender;
  final String joinPolicy;
  final double? distanceKm;
  final String status;
  final bool isPublic;

  factory ActivityItem.fromMap(Map<String, dynamic> map) {
    final rawStartsAt = map['starts_at'] as String?;
    final rawDistance = map['distance_km'] ?? map['distance'];

    final profile = map['profiles'] as Map<String, dynamic>?;
    final hostName = map['host_name'] as String? ??
        map['creator_name'] as String? ??
        profile?['display_name'] as String? ??
        profile?['username'] as String?;
    final hostAvatarUrl = map['host_avatar_url'] as String? ??
        profile?['avatar_url'] as String?;

    final teamsList = map['teams'] as List<dynamic>?;
    final firstTeam = teamsList != null && teamsList.isNotEmpty
        ? teamsList.first as Map<String, dynamic>?
        : null;

    final targetGender = map['target_gender'] as String? ??
        firstTeam?['target_gender'] as String? ??
        'all';
    final joinPolicy = map['join_policy'] as String? ??
        firstTeam?['join_policy'] as String? ??
        'everyone';

    return ActivityItem(
      id: map['id'] as String? ?? '',
      creatorId: map['creator_id'] as String?,
      hostName: hostName,
      hostAvatarUrl: hostAvatarUrl,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'walking',
      locationName: map['location_name'] as String? ?? '',
      maxMembers: (map['max_members'] as num?)?.toInt() ?? 5,
      startsAt: rawStartsAt != null
          ? DateTime.tryParse(rawStartsAt) ?? DateTime.now()
          : DateTime.now(),
      skillLevel: map['skill_level'] as String? ?? 'all',
      preparationNotes: map['preparation_notes'] as String? ?? '',
      targetGender: targetGender,
      joinPolicy: joinPolicy,
      distanceKm: (rawDistance as num?)?.toDouble(),
      status: map['status'] as String? ?? 'open',
      isPublic: map['is_public'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creator_id': creatorId,
      'host_name': hostName,
      'host_avatar_url': hostAvatarUrl,
      'title': title,
      'description': description,
      'type': type,
      'location_name': locationName,
      'max_members': maxMembers,
      'starts_at': startsAt.toIso8601String(),
      'skill_level': skillLevel,
      'preparation_notes': preparationNotes,
      'target_gender': targetGender,
      'join_policy': joinPolicy,
      'distance_km': distanceKm,
      'status': status,
      'is_public': isPublic,
    };
  }

  ActivityItem copyWith({
    String? id,
    String? creatorId,
    String? hostName,
    String? hostAvatarUrl,
    String? title,
    String? description,
    String? type,
    String? locationName,
    int? maxMembers,
    DateTime? startsAt,
    String? skillLevel,
    String? preparationNotes,
    String? targetGender,
    String? joinPolicy,
    double? distanceKm,
    String? status,
    bool? isPublic,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      locationName: locationName ?? this.locationName,
      maxMembers: maxMembers ?? this.maxMembers,
      startsAt: startsAt ?? this.startsAt,
      skillLevel: skillLevel ?? this.skillLevel,
      preparationNotes: preparationNotes ?? this.preparationNotes,
      targetGender: targetGender ?? this.targetGender,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      distanceKm: distanceKm ?? this.distanceKm,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

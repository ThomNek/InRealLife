class TeamItem {
  const TeamItem({
    required this.id,
    required this.hostId,
    this.activityId,
    required this.name,
    this.description = '',
    required this.maxMembers,
    this.currentMembers = 1,
    this.status = 'recruiting',
    this.targetGender = 'all',
    this.joinPolicy = 'everyone',
    this.distanceKm,
    this.myRequestStatus,
    this.createdAt,
  });

  final String id;
  final String hostId;
  final String? activityId;
  final String name;
  final String description;
  final int maxMembers;
  final int currentMembers;
  final String status;
  final String targetGender;
  final String joinPolicy;
  final double? distanceKm;
  final String? myRequestStatus;
  final DateTime? createdAt;

  bool get isFull => currentMembers >= maxMembers;

  factory TeamItem.fromMap(Map<String, dynamic> map) {
    final rawCreated = map['created_at'] as String?;
    final rawDistance = map['distance_km'] ?? map['distance'];

    // Handle nested team_members(count) from Supabase select
    int memberCount = 1;
    final membersData = map['team_members'];
    if (membersData is List && membersData.isNotEmpty) {
      final first = membersData.first;
      if (first is Map && first['count'] != null) {
        memberCount = (first['count'] as num).toInt();
      } else {
        memberCount = membersData.length;
      }
    } else if (map['current_members'] != null) {
      memberCount = (map['current_members'] as num).toInt();
    }

    return TeamItem(
      id: map['id'] as String? ?? '',
      hostId: map['host_id'] as String? ?? '',
      activityId: map['activity_id'] as String?,
      name: map['name'] as String? ?? 'Đội khám phá',
      description: map['description'] as String? ?? '',
      maxMembers: (map['max_members'] as num?)?.toInt() ?? 4,
      currentMembers: memberCount,
      status: map['status'] as String? ?? 'recruiting',
      targetGender: map['target_gender'] as String? ?? 'all',
      joinPolicy: map['join_policy'] as String? ?? 'everyone',
      distanceKm: (rawDistance as num?)?.toDouble(),
      myRequestStatus: map['my_request_status'] as String?,
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'host_id': hostId,
      'activity_id': activityId,
      'name': name,
      'description': description,
      'max_members': maxMembers,
      'current_members': currentMembers,
      'status': status,
      'target_gender': targetGender,
      'join_policy': joinPolicy,
      'distance_km': distanceKm,
      'my_request_status': myRequestStatus,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  TeamItem copyWith({
    String? id,
    String? hostId,
    String? activityId,
    String? name,
    String? description,
    int? maxMembers,
    int? currentMembers,
    String? status,
    String? targetGender,
    String? joinPolicy,
    double? distanceKm,
    String? myRequestStatus,
    DateTime? createdAt,
  }) {
    return TeamItem(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      activityId: activityId ?? this.activityId,
      name: name ?? this.name,
      description: description ?? this.description,
      maxMembers: maxMembers ?? this.maxMembers,
      currentMembers: currentMembers ?? this.currentMembers,
      status: status ?? this.status,
      targetGender: targetGender ?? this.targetGender,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      distanceKm: distanceKm ?? this.distanceKm,
      myRequestStatus: myRequestStatus ?? this.myRequestStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

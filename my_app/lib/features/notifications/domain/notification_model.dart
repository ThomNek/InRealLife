class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.metadata,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? metadata;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    final rawCreated = map['created_at'] as String?;
    final rawRead = map['read_at'] as String?;
    return NotificationItem(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      metadata: map['metadata'] as Map<String, dynamic>?,
      readAt: rawRead != null ? DateTime.tryParse(rawRead) : null,
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'metadata': metadata,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderDisplayName,
    required this.content,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? senderDisplayName;
  final String content;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool isMine(String? currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final rawCreated = map['created_at'] as String?;
    final rawRead = map['read_at'] as String?;
    return ChatMessage(
      id: map['id'] as String? ?? '',
      conversationId: map['conversation_id'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      senderDisplayName: map['sender_display_name'] as String?,
      content: map['content'] as String? ?? '',
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) : null,
      readAt: rawRead != null ? DateTime.tryParse(rawRead) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_display_name': senderDisplayName,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}

class ChatConversation {
  const ChatConversation({
    required this.conversationId,
    this.otherUserId,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.conversationType = 'direct',
    this.lastMessage,
    this.unreadCount = 0,
    this.teamId,
  });

  final String conversationId;
  final String? otherUserId;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String conversationType;
  final String? lastMessage;
  final int unreadCount;
  final String? teamId;

  bool get isTeam => conversationType == 'team';

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      conversationId: map['conversation_id'] as String? ?? '',
      otherUserId: map['other_user_id'] as String?,
      displayName: map['display_name'] as String?,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      conversationType: map['conversation_type'] as String? ?? 'direct',
      lastMessage: map['last_message'] as String?,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      teamId: map['team_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'other_user_id': otherUserId,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'conversation_type': conversationType,
      'last_message': lastMessage,
      'unread_count': unreadCount,
      'team_id': teamId,
    };
  }
}

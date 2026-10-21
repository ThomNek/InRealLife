import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_irl/features/activities/domain/activity_model.dart';
import 'package:treasure_irl/features/chat/domain/chat_models.dart';
import 'package:treasure_irl/features/friends/domain/friend_model.dart';
import 'package:treasure_irl/features/notifications/domain/notification_model.dart';
import 'package:treasure_irl/features/profile/domain/profile_progress.dart';
import 'package:treasure_irl/features/profile/domain/user_profile.dart';
import 'package:treasure_irl/features/teams/domain/team_model.dart';

void main() {
  group('UserProfile Model', () {
    test('parses fromMap and converts toMap with defaults', () {
      final map = {
        'id': 'usr-1',
        'display_name': 'Nguyen Van A',
        'username': 'nguyena',
        'city': 'Hanoi',
        'level': 3,
        'exp': 1500,
      };

      final profile = UserProfile.fromMap(map);
      expect(profile.id, 'usr-1');
      expect(profile.displayName, 'Nguyen Van A');
      expect(profile.username, 'nguyena');
      expect(profile.city, 'Hanoi');
      expect(profile.level, 3);
      expect(profile.exp, 1500);
      expect(profile.profileVisibility, 'public');
      expect(profile.showAge, true);

      final toMap = profile.toMap();
      expect(toMap['display_name'], 'Nguyen Van A');
      expect(toMap['level'], 3);

      final updated = profile.copyWith(displayName: 'Nguyen Van B', level: 4);
      expect(updated.displayName, 'Nguyen Van B');
      expect(updated.level, 4);
      expect(updated.id, 'usr-1');
    });

    test('ProfileProgress works with UserProfile model', () {
      const profile = UserProfile(
        id: 'usr-1',
        displayName: 'Test',
        level: 2,
        exp: 500,
      );
      final progress = ProfileProgress.fromModel(profile);
      expect(progress.level, 2);
      expect(progress.exp, 500);
      expect(progress.target, 2000);
      expect(progress.fraction, 0.25);
      expect(progress.remaining, 1500);
    });
  });

  group('Friend Models', () {
    test('FriendItem and FriendRequestItem parse correctly', () {
      final friend = FriendItem.fromMap({
        'id': 'f-1',
        'display_name': 'Friend One',
        'username': 'fone',
        'city': 'HCM',
        'status': 'accepted',
      });
      expect(friend.id, 'f-1');
      expect(friend.displayName, 'Friend One');
      expect(friend.status, 'accepted');

      final req = FriendRequestItem.fromMap({
        'id': 'req-1',
        'display_name': 'Requester',
        'created_at': '2026-10-12T08:00:00.000Z',
      });
      expect(req.id, 'req-1');
      expect(req.createdAt, isNotNull);
    });
  });

  group('Chat Models', () {
    test('ChatMessage and ChatConversation compute properties properly', () {
      final msg = ChatMessage.fromMap({
        'id': 'msg-1',
        'conversation_id': 'c-1',
        'sender_id': 'u-1',
        'content': 'Hello world',
      });
      expect(msg.isMine('u-1'), isTrue);
      expect(msg.isMine('u-2'), isFalse);

      final conv = ChatConversation.fromMap({
        'conversation_id': 'c-1',
        'display_name': 'Team Alpha',
        'conversation_type': 'team',
        'unread_count': 3,
      });
      expect(conv.isTeam, isTrue);
      expect(conv.unreadCount, 3);
    });
  });

  group('ActivityItem Model', () {
    test('parses and handles distances, dates, host info and join requirements', () {
      final activity = ActivityItem.fromMap({
        'id': 'act-1',
        'title': 'Săn rương',
        'description': 'Mô tả',
        'type': 'treasure_hunt',
        'location_name': 'Công viên',
        'max_members': 4,
        'distance_km': 1.5,
        'status': 'open',
        'host_name': 'Host Anh',
        'target_gender': 'female_only',
        'join_policy': 'friends_only',
      });
      expect(activity.id, 'act-1');
      expect(activity.title, 'Săn rương');
      expect(activity.distanceKm, 1.5);
      expect(activity.maxMembers, 4);
      expect(activity.hostName, 'Host Anh');
      expect(activity.targetGender, 'female_only');
      expect(activity.joinPolicy, 'friends_only');

      final copied = activity.copyWith(hostName: 'Host Binh');
      expect(copied.hostName, 'Host Binh');
      expect(copied.targetGender, 'female_only');

      // Test parsing from nested profile and teams relation
      final fromJoined = ActivityItem.fromMap({
        'id': 'act-2',
        'title': 'Đi dạo',
        'description': 'Mô tả',
        'type': 'walking',
        'location_name': 'Bờ hồ',
        'max_members': 6,
        'profiles': {
          'display_name': 'Tran Van C',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
        'teams': [
          {
            'target_gender': 'male_only',
            'join_policy': 'everyone',
          }
        ],
      });
      expect(fromJoined.hostName, 'Tran Van C');
      expect(fromJoined.hostAvatarUrl, 'https://example.com/avatar.jpg');
      expect(fromJoined.targetGender, 'male_only');
      expect(fromJoined.joinPolicy, 'everyone');
    });
  });

  group('TeamItem Model', () {
    test('computes member counts and isFull', () {
      final team = TeamItem.fromMap({
        'id': 't-1',
        'host_id': 'h-1',
        'name': 'Đội Thần Tốc',
        'max_members': 4,
        'team_members': [
          {'count': 4}
        ],
      });
      expect(team.currentMembers, 4);
      expect(team.isFull, isTrue);
    });
  });

  group('NotificationItem Model', () {
    test('determines isRead state correctly', () {
      final unread = NotificationItem.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'title': 'Tin nhắn mới',
        'body': 'Nội dung',
        'type': 'chat',
      });
      expect(unread.isRead, isFalse);

      final read = NotificationItem.fromMap({
        'id': 'n-2',
        'user_id': 'u-1',
        'title': 'Đã đọc',
        'body': 'Nội dung',
        'type': 'chat',
        'read_at': '2026-10-12T08:00:00.000Z',
      });
      expect(read.isRead, isTrue);
    });
  });
}

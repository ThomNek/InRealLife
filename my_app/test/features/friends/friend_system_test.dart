import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_irl/core/theme/app_theme.dart';
import 'package:treasure_irl/features/chat/data/chat_repository.dart';
import 'package:treasure_irl/features/friends/data/friend_repository.dart';
import 'package:treasure_irl/features/home/presentation/widgets/chat_panel.dart';

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository() : super();

  @override
  String? get currentUserId => 'user-me';

  @override
  Future<List<Map<String, dynamic>>> fetchPeople() async => [
        {
          'id': 'user-1',
          'display_name': 'Nguyen Van A',
          'username': 'nguyena',
          'city': 'Hanoi',
        },
        {
          'id': 'user-2',
          'display_name': 'Tran Thi B',
          'username': 'tranb',
          'city': 'Da Nang',
        },
      ];

  @override
  Future<List<Map<String, dynamic>>> fetchInbox() async => [
        {
          'conversation_id': 'conv-1',
          'other_user_id': 'user-1',
          'display_name': 'Nguyen Van A',
          'username': 'nguyena',
          'conversation_type': 'direct',
          'last_message': 'Xin chao!',
          'unread_count': 1,
        },
      ];

  @override
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) =>
      Stream.value([
        {
          'id': 'msg-1',
          'sender_id': 'user-1',
          'content': 'Xin chao!',
        },
      ]);
}

class _FakeFriendRepository extends FriendRepository {
  _FakeFriendRepository() : super();

  @override
  String? get currentUserId => 'user-me';

  @override
  Future<List<Map<String, dynamic>>> fetchFriends() async => [
        {
          'id': 'user-1',
          'display_name': 'Nguyen Van A',
          'username': 'nguyena',
          'city': 'Hanoi',
          'status': 'accepted',
        },
      ];

  @override
  Future<List<Map<String, dynamic>>> fetchPendingReceivedRequests() async => [
        {
          'id': 'user-2',
          'display_name': 'Tran Thi B',
          'username': 'tranb',
          'city': 'Da Nang',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

  @override
  Future<Map<String, String>> fetchFriendshipStatusMap() async => {
        'user-1': 'accepted',
        'user-2': 'received',
      };

  @override
  Stream<List<Map<String, dynamic>>> watchFriendships() => const Stream.empty();
}

void main() {
  test('FriendRepository gracefully handles unauthenticated client', () async {
    final repo = FriendRepository();
    final friends = await repo.fetchFriends();
    expect(friends, isEmpty);

    final requests = await repo.fetchPendingReceivedRequests();
    expect(requests, isEmpty);

    final map = await repo.fetchFriendshipStatusMap();
    expect(map, isEmpty);
  });

  testWidgets('HomeChatPanel renders and switches tabs correctly',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeChat = _FakeChatRepository();
    final fakeFriend = _FakeFriendRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: HomeChatPanel(
            isStandalonePage: true,
            chatRepository: fakeChat,
            friendRepository: fakeFriend,
          ),
        ),
      ),
    );

    // Initial pump for futures
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Search
    expect(find.text('Tin nhắn & Bạn bè'), findsOneWidget);
    expect(find.text('Hộp thư'), findsOneWidget);
    expect(find.text('Bạn bè (1)'), findsOneWidget);
    expect(find.text('Lời mời'), findsOneWidget);
    expect(find.text('Khám phá'), findsOneWidget);

    // Initial tab is Hộp thư -> Nguyen Van A should be listed with last message
    expect(find.text('Nguyen Van A'), findsOneWidget);
    expect(find.text('Xin chao!'), findsOneWidget);

    // Switch to Bạn bè tab
    await tester.tap(find.text('Bạn bè (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('@nguyena'), findsOneWidget);

    // Switch to Lời mời tab
    await tester.tap(find.text('Lời mời'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tran Thi B'), findsOneWidget);
    expect(find.text('Đồng ý'), findsOneWidget);

    // Switch to Khám phá tab
    await tester.tap(find.text('Khám phá'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Bạn bè'), findsWidgets);
    expect(find.text('Chấp nhận'), findsOneWidget);
  });
}

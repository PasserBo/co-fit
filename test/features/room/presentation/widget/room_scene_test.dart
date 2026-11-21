import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/avatar/presentation/renderer/vector_avatar_renderer.dart';
import 'package:cofit/features/room/domain/entity/room_presence_member.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:cofit/features/room/presentation/widget/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RoomPresenceMember _member(
  String id,
  UserActivityState state, {
  String? action,
  int? remaining,
}) {
  return RoomPresenceMember(
    clientId: id,
    userId: id,
    activityStatus: UserActivityStatusEntity(
      activityState: state,
      templateName: action,
      remainingSec: remaining,
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ).copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  _withSelfPresentTests();
  _withOfflineMembersTests();

  testWidgets('offline member renders dimmed with 离线 chip', (tester) async {
    await _pump(
      tester,
      RoomScene(
        renderer: const VectorAvatarRenderer(),
        members: const [
          RoomPresenceMember(
            clientId: 'offline-friend_beta',
            userId: 'friend_beta',
            nickname: '小贝',
          ),
          RoomPresenceMember(clientId: 'c-me', userId: 'me'),
        ],
        offlineUserIds: const {'friend_beta'},
        selfUserId: 'me',
      ),
    );
    await tester.pump();

    expect(find.text('小贝'), findsOneWidget);
    expect(find.text('离线'), findsOneWidget);
    expect(find.text('挂机'), findsOneWidget); // 只有自己是在线待机
    // 名字行自带一层透明度(今日面板台上淡出用);取最外层 = 整个小人的变暗。
    final opacity = tester.widgetList<Opacity>(
      find.ancestor(of: find.text('小贝'), matching: find.byType(Opacity)),
    ).last;
    expect(opacity.opacity, CoFitOpacities.avatarInactive);
  });

  testWidgets('renders friends with truncated names and self as 你', (
    tester,
  ) async {
    await _pump(
      tester,
      RoomScene(
        renderer: const VectorAvatarRenderer(),
        members: [
          _member(
            'friend_alpha',
            UserActivityState.active,
            action: '深蹲',
            remaining: 300,
          ),
          _member('me_user', UserActivityState.idle),
        ],
        selfUserId: 'me_user',
      ),
    );
    await tester.pump();

    expect(find.text('friend'), findsOneWidget); // userId 前 6 位
    expect(find.text('你'), findsOneWidget);
    expect(find.text('me_use'), findsNothing); // 自己不按截断名显示
  });

  testWidgets('active member shows action chip with remaining minutes', (
    tester,
  ) async {
    await _pump(
      tester,
      RoomScene(
        renderer: const VectorAvatarRenderer(),
        members: [
          _member(
            'friend_alpha',
            UserActivityState.active,
            action: '深蹲',
            remaining: 300,
          ),
        ],
        selfUserId: 'me',
      ),
    );
    await tester.pump();

    expect(find.text('深蹲 5min'), findsOneWidget);
  });

  testWidgets('idle member falls back to 挂机 chip', (tester) async {
    await _pump(
      tester,
      RoomScene(
        renderer: const VectorAvatarRenderer(),
        members: [_member('friend_alpha', UserActivityState.idle)],
        selfUserId: 'me',
      ),
    );
    await tester.pump();

    expect(find.text('挂机'), findsOneWidget);
  });
}

void _withSelfPresentTests() {
  group('withSelfPresent', () {
    const self = RoomPresenceMember(clientId: 'c-me', userId: 'me');
    const other = RoomPresenceMember(clientId: 'c-o', userId: 'other');

    test('returns the same list when self already present', () {
      final result = withSelfPresent([other, self], selfUserId: 'me');
      expect(result, [other, self]);
    });

    test('appends a local self with nickname/status when missing', () {
      final result = withSelfPresent(
        [other],
        selfUserId: 'me',
        nickname: '我',
        activityStatus: const UserActivityStatusEntity(
          activityState: UserActivityState.active,
        ),
      );
      expect(result.length, 2);
      expect(result.last.userId, 'me');
      expect(result.last.nickname, '我');
      expect(
        result.last.activityStatus.activityState,
        UserActivityState.active,
      );
    });

    test('empty presence still yields self (idle)', () {
      final result = withSelfPresent(const [], selfUserId: 'me');
      expect(result.single.userId, 'me');
      expect(
        result.single.activityStatus.activityState,
        UserActivityState.idle,
      );
    });
  });
}

void _withOfflineMembersTests() {
  group('withOfflineMembers', () {
    const me = RoomPresenceMember(clientId: 'c-me', userId: 'me');
    const a1 = RoomPresenceMember(clientId: 'c-a1', userId: 'a');
    const a2 = RoomPresenceMember(clientId: 'c-a2', userId: 'a');

    test('orders by roster, fills offline placeholders with nickname', () {
      final roster = withOfflineMembers(
        [me, a1],
        rosterIds: ['owner', 'a', 'me'],
        nicknames: {'owner': '房主大人'},
      );
      expect(roster.members.map((m) => m.userId), ['owner', 'a', 'me']);
      expect(roster.offlineUserIds, {'owner'});
      expect(roster.members.first.clientId, 'offline-owner');
      expect(roster.members.first.nickname, '房主大人');
      expect(
        roster.members.first.activityStatus.activityState,
        UserActivityState.idle,
      );
    });

    test('dedupes multi-device presence and appends unlisted online', () {
      final roster = withOfflineMembers([a1, a2, me], rosterIds: ['a']);
      expect(roster.members, [a1, me]);
      expect(roster.offlineUserIds, isEmpty);
    });
  });
}

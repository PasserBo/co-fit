import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/room/domain/entity/room_info_entity.dart';
import 'package:cofit/features/room/domain/entity/room_presence_member.dart';
import 'package:cofit/features/room/presentation/room_browser_provider.dart';
import 'package:cofit/features/room/presentation/view/report_sheet_view.dart';
import 'package:cofit/features/room/presentation/view/room_members_sheet_view.dart';
import 'package:cofit/features/room/provider/member_nickname_provider.dart';
import 'package:cofit/features/room/provider/room_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _roomId = 'room-1';

final _room = RoomInfoEntity.fromMap({
  'roomId': _roomId,
  'name': '晨练小队',
  'ownerId': 'owner',
  'members': {
    'owner': {'role': 'owner'},
    'alice': {'role': 'member'},
    'bob': {'role': 'member'},
  },
});

const _presence = [
  RoomPresenceMember(clientId: 'c1', userId: 'owner', nickname: '队长'),
  RoomPresenceMember(clientId: 'c2', userId: 'alice', nickname: '小爱'),
];

/// IdleAvatarFigure 有常驻呼吸动画,pumpAndSettle 永远不会稳定 → 定量 pump。
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        roomInfoProvider(_roomId).overrideWith((ref) => Stream.value(_room)),
        roomPresenceByIdProvider(_roomId).overrideWithValue(_presence),
        // 离线成员 bob 的昵称走 profile
        memberNicknameProvider('bob').overrideWith((ref) => Stream.value('鲍勃')),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
        ).copyWith(extensions: [CoFitColors.dark]),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('RoomMembersSheetView', () {
    testWidgets('owner sees all members, online state, and 移出 on others', (
      tester,
    ) async {
      await _pump(
        tester,
        const RoomMembersSheetView(roomId: _roomId, viewerId: 'owner'),
      );
      await _settle(tester);

      expect(find.text('3 名成员 · 2 人在线'), findsOneWidget);
      expect(find.text('队长(我)'), findsOneWidget);
      expect(find.text('小爱'), findsOneWidget);
      expect(find.text('鲍勃'), findsOneWidget); // profile 昵称
      expect(find.text('房主'), findsOneWidget);
      expect(find.text('在线'), findsNWidgets(2));
      expect(find.text('离线'), findsOneWidget);
      // 不能移出自己/房主 → 只有 alice、bob 两个「移出」
      expect(find.text('移出'), findsNWidgets(2));
    });

    testWidgets('member sees no 移出 buttons', (tester) async {
      await _pump(
        tester,
        const RoomMembersSheetView(roomId: _roomId, viewerId: 'alice'),
      );
      await _settle(tester);

      expect(find.text('小爱(我)'), findsOneWidget);
      expect(find.text('移出'), findsNothing);
    });

    testWidgets('移出 opens a confirm dialog', (tester) async {
      await _pump(
        tester,
        const RoomMembersSheetView(roomId: _roomId, viewerId: 'owner'),
      );
      await _settle(tester);

      await tester.tap(find.text('移出').first);
      await _settle(tester);

      expect(find.text('移出「小爱」?'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await _settle(tester);
      expect(find.text('移出「小爱」?'), findsNothing);
    });
  });

  group('ReportSheetView', () {
    testWidgets('lists room + other members as targets, requires reason', (
      tester,
    ) async {
      await _pump(
        tester,
        const ReportSheetView(
          roomId: _roomId,
          roomName: '晨练小队',
          reporterId: 'alice',
        ),
      );
      await _settle(tester);

      expect(find.text('房间内容'), findsOneWidget);
      expect(find.text('队长'), findsOneWidget);
      expect(find.text('鲍勃'), findsOneWidget);
      expect(find.text('小爱'), findsNothing); // 不含自己

      await tester.tap(find.text('提交举报'));
      await tester.pump();
      expect(find.text('请填写举报原因'), findsOneWidget);
    });
  });

  group('removed-member helpers', () {
    test(
      'wasRemovedFromRoom is true only for non-members of an existing room',
      () {
        expect(wasRemovedFromRoom(_room, 'alice'), isFalse);
        expect(wasRemovedFromRoom(_room, 'owner'), isFalse);
        expect(wasRemovedFromRoom(_room, 'carol'), isTrue);
        expect(wasRemovedFromRoom(null, 'carol'), isFalse);
      },
    );

    test('roomMemberIdsOf orders owner → memberIds → presence-only', () {
      const extra = [RoomPresenceMember(clientId: 'c9', userId: 'ghost')];
      expect(roomMemberIdsOf(_room, [..._presence, ...extra]), [
        'owner',
        'alice',
        'bob',
        'ghost',
      ]);
    });
  });
}

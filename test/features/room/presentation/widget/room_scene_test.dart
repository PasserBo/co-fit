import 'package:cofit/core/theme/cofit_colors.dart';
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
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders friends with truncated names and self as 你',
      (tester) async {
    await _pump(
      tester,
      RoomScene(
        members: [
          _member('friend_alpha', UserActivityState.active,
              action: '深蹲', remaining: 300),
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

  testWidgets('active member shows action chip with remaining minutes',
      (tester) async {
    await _pump(
      tester,
      RoomScene(
        members: [
          _member('friend_alpha', UserActivityState.active,
              action: '深蹲', remaining: 300),
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
        members: [_member('friend_alpha', UserActivityState.idle)],
        selfUserId: 'me',
      ),
    );
    await tester.pump();

    expect(find.text('挂机'), findsOneWidget);
  });
}

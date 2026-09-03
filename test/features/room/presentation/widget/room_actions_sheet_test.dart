import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/room/presentation/widget/room_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool isOwner,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: RoomActionsSheet(roomName: '考研自习室', isOwner: isOwner),
      ),
    ),
  );
}

void main() {
  testWidgets('member sees only leave action', (tester) async {
    await _pump(tester, isOwner: false);

    expect(find.text('考研自习室'), findsOneWidget);
    expect(find.text('退出房间'), findsOneWidget);
    expect(find.text('解散房间'), findsNothing);
    expect(find.text('编辑房间信息'), findsNothing);
  });

  testWidgets('owner sees edit/invite/dissolve and badge, no leave',
      (tester) async {
    await _pump(tester, isOwner: true);

    expect(find.text('房主'), findsOneWidget);
    expect(find.text('编辑房间信息'), findsOneWidget);
    expect(find.text('邀请好友'), findsOneWidget);
    expect(find.text('解散房间'), findsOneWidget);
    expect(find.text('退出房间'), findsNothing);
  });

  testWidgets('rows pop with the corresponding action', (tester) async {
    Future<RoomSheetAction?> open(
      WidgetTester tester, {
      required bool isOwner,
      required String rowText,
    }) async {
      RoomSheetAction? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark)
              .copyWith(extensions: [CoFitColors.dark]),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<RoomSheetAction>(
                      context: context,
                      builder: (_) => RoomActionsSheet(
                        roomName: '考研自习室',
                        isOwner: isOwner,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(rowText));
      await tester.pumpAndSettle();
      return result;
    }

    expect(
      await open(tester, isOwner: false, rowText: '退出房间'),
      RoomSheetAction.leave,
    );
    expect(
      await open(tester, isOwner: true, rowText: '解散房间'),
      RoomSheetAction.dissolve,
    );
    expect(
      await open(tester, isOwner: true, rowText: '编辑房间信息'),
      RoomSheetAction.editInfo,
    );
  });
}

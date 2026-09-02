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
  testWidgets('member sees leave action', (tester) async {
    await _pump(tester, isOwner: false);

    expect(find.text('考研自习室'), findsOneWidget);
    expect(find.text('退出房间'), findsOneWidget);
  });

  testWidgets('owner cannot leave', (tester) async {
    await _pump(tester, isOwner: true);

    expect(find.text('退出房间'), findsNothing);
    expect(find.text('你是房主,暂不支持退出或解散房间'), findsOneWidget);
  });

  testWidgets('tapping leave pops with RoomSheetAction.leave', (tester) async {
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
                    builder: (_) => const RoomActionsSheet(
                      roomName: '考研自习室',
                      isOwner: false,
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
    await tester.tap(find.text('退出房间'));
    await tester.pumpAndSettle();

    expect(result, RoomSheetAction.leave);
  });
}

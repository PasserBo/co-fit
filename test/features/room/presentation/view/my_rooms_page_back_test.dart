import 'package:cofit/core/navigation/app_shell.dart';
import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/room/presentation/room_browser_provider.dart';
import 'package:cofit/features/room/presentation/view/my_rooms_page_view.dart';
import 'package:cofit/features/room/provider/room_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 已加入两间房的浏览状态(非空列表才会出现右上「新建」按钮——
/// 回归点:它曾以无界宽度撑坏 AppBar,导致左上返回键点了没反应)。
class _JoinedRoomsNotifier extends RoomBrowserNotifier {
  @override
  RoomBrowserState build() => const RoomBrowserState(
    joinedRoomIds: ['r1', 'r2'],
    focusedRoomId: 'r1',
    isReady: true,
  );
}

void main() {
  testWidgets('tapping back closes MyRoomsPageView when rooms are listed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomBrowserProvider.overrideWith(_JoinedRoomsNotifier.new),
          roomInfoProvider.overrideWith((ref, roomId) => const Stream.empty()),
        ],
        child: MaterialApp(
          theme: CoFitTheme.dark,
          home: AppShell(
            pages: [
              Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MyRoomsPageView(userId: 'u1'),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
              const SizedBox(),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('我的房间'), findsOneWidget);
    expect(find.text('新建'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('我的房间'), findsNothing);
  });
}

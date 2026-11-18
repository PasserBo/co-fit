import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/room/domain/entity/room_info_entity.dart';
import 'package:cofit/features/room/presentation/view/room_create_page_view.dart';
import 'package:cofit/features/room/presentation/view/room_discover_page_view.dart';
import 'package:cofit/features/room/presentation/widget/public_room_tile.dart';
import 'package:cofit/features/room/presentation/widget/room_visibility_option.dart';
import 'package:cofit/features/room/provider/public_rooms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RoomInfoEntity _room(String id, String name, {int members = 1}) {
  return RoomInfoEntity(
    roomId: id,
    name: name,
    description: '',
    visibility: RoomVisibility.public,
    ownerId: 'owner',
    shareLinkHash: 'h',
    shareSalt: 's',
    memberIds: [for (var i = 0; i < members; i++) 'u$i'],
  );
}

Widget _app(Widget home, {List<Object> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(theme: CoFitTheme.dark, home: home),
  );
}

void main() {
  group('RoomCreatePageView', () {
    testWidgets('defaults to public and disables submit for blank names', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const RoomCreatePageView(userId: 'u1')));
      await tester.pump();

      final options = tester
          .widgetList<RoomVisibilityOption>(find.byType(RoomVisibilityOption))
          .toList();
      expect(options.first.title, '公开');
      expect(options.first.selected, isTrue);
      expect(options.last.selected, isFalse);

      FilledButton submit() => tester.widget<FilledButton>(
        find.byKey(const Key('room-create-submit')),
      );
      expect(submit().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('room-create-name')),
        '   ',
      );
      await tester.pump();
      expect(submit().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('room-create-name')),
        '晨练小队',
      );
      await tester.pump();
      expect(submit().onPressed, isNotNull);

      await tester.tap(find.text('仅邀请'));
      await tester.pump();
      final after = tester
          .widgetList<RoomVisibilityOption>(find.byType(RoomVisibilityOption))
          .toList();
      expect(after.last.selected, isTrue);
    });

    testWidgets('name field caps at the length limit', (tester) async {
      await tester.pumpWidget(_app(const RoomCreatePageView(userId: 'u1')));
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const Key('room-create-name')),
      );
      expect(field.maxLength, RoomInfoLimits.nameMaxLength);
    });
  });

  group('RoomDiscoverPageView', () {
    testWidgets('lists public rooms and filters by search', (tester) async {
      await tester.pumpWidget(
        _app(
          const RoomDiscoverPageView(userId: 'u1'),
          overrides: [
            publicRoomsProvider.overrideWith(
              (ref) async => [
                _room('a', '晨练小队', members: 3),
                _room('b', '夜跑俱乐部'),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PublicRoomTile), findsNWidgets(2));
      expect(find.text('3 名成员'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('room-discover-search')),
        '晨练',
      );
      await tester.pump();
      expect(find.byType(PublicRoomTile), findsOneWidget);
      expect(find.text('夜跑俱乐部'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('room-discover-search')),
        '游泳',
      );
      await tester.pump();
      expect(find.text('没有找到匹配的房间'), findsOneWidget);
    });

    testWidgets('empty list offers creating a room', (tester) async {
      await tester.pumpWidget(
        _app(
          const RoomDiscoverPageView(userId: 'u1'),
          overrides: [
            publicRoomsProvider.overrideWith((ref) async => <RoomInfoEntity>[]),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('暂时还没有公开房间'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '新建房间'), findsOneWidget);
    });

    testWidgets('load failure shows retry', (tester) async {
      await tester.pumpWidget(
        _app(
          const RoomDiscoverPageView(userId: 'u1'),
          overrides: [
            publicRoomsProvider.overrideWith(
              (ref) async => throw Exception('offline'),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '重试'), findsOneWidget);
    });
  });
}

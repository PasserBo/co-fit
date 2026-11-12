import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/presentation/widget/card_fan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<ActionTemplateCard> _cards(int count) => [
  for (var i = 0; i < count; i++)
    ActionTemplateCard(
      id: 'c$i',
      name: '动作$i',
      type: ActionType.strength,
      rawType: 'strength',
      source: ActionSource.official,
      ablyActionId: 'c$i',
      defaultDurationSec: 600,
    ),
];

Future<void> _pump(WidgetTester tester, Widget fan) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ).copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: Stack(
          children: [Positioned(left: 0, right: 0, bottom: 0, child: fan)],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all cards and empty state', (tester) async {
    await _pump(
      tester,
      CardFan(cards: _cards(3), focused: false, centerIndex: 1),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      expect(find.text('动作$i'), findsOneWidget);
    }

    await _pump(
      tester,
      const CardFan(cards: [], focused: false, centerIndex: 0),
    );
    expect(find.text('当前牌组还没有卡'), findsOneWidget);
  });

  testWidgets('collapsed tap requests focus mode', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      CardFan(
        cards: _cards(3),
        focused: false,
        centerIndex: 1,
        onTapCollapsed: () => tapped = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('动作1'));
    expect(tapped, isTrue);
  });

  testWidgets('focused: tapping a side card requests re-centering', (
    tester,
  ) async {
    int? focusedIndex;
    await _pump(
      tester,
      CardFan(
        cards: _cards(3),
        focused: true,
        centerIndex: 1,
        onFocusCard: (i) => focusedIndex = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('动作2'), warnIfMissed: false);
    expect(focusedIndex, 2);
  });

  testWidgets('focused: swiping the center card up plays it', (tester) async {
    ActionTemplateCard? played;
    await _pump(
      tester,
      CardFan(
        cards: _cards(3),
        focused: true,
        centerIndex: 1,
        onPlay: (card) => played = card,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('动作1'),
      const Offset(0, -120),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(played?.id, 'c1');
  });

  testWidgets('focused: swiping the fan left moves the center to the right', (
    tester,
  ) async {
    int? focusedIndex;
    await _pump(
      tester,
      CardFan(
        cards: _cards(3),
        focused: true,
        centerIndex: 1,
        onFocusCard: (i) => focusedIndex = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CardFan), const Offset(-160, 0));
    await tester.pumpAndSettle();

    expect(focusedIndex, 2);
  });

  group('resolveSwipeTarget', () {
    const step = 80.0;

    test('rounds to the nearest card by distance', () {
      expect(
        CardFan.resolveSwipeTarget(
          center: 1,
          count: 5,
          dragX: -100,
          stepPx: step,
          velocityDx: 0,
        ),
        2,
      );
      expect(
        CardFan.resolveSwipeTarget(
          center: 1,
          count: 5,
          dragX: 30,
          stepPx: step,
          velocityDx: 0,
        ),
        1,
      );
      expect(
        CardFan.resolveSwipeTarget(
          center: 2,
          count: 5,
          dragX: 170,
          stepPx: step,
          velocityDx: 0,
        ),
        0,
      );
    });

    test('a quick short fling still switches one card', () {
      expect(
        CardFan.resolveSwipeTarget(
          center: 1,
          count: 3,
          dragX: 20,
          stepPx: step,
          velocityDx: 900,
        ),
        0,
      );
      expect(
        CardFan.resolveSwipeTarget(
          center: 1,
          count: 3,
          dragX: -20,
          stepPx: step,
          velocityDx: -900,
        ),
        2,
      );
      // 慢速短距:不切
      expect(
        CardFan.resolveSwipeTarget(
          center: 1,
          count: 3,
          dragX: 20,
          stepPx: step,
          velocityDx: 100,
        ),
        1,
      );
    });

    test('clamps at both ends', () {
      expect(
        CardFan.resolveSwipeTarget(
          center: 2,
          count: 3,
          dragX: -500,
          stepPx: step,
          velocityDx: -3000,
        ),
        2,
      );
      expect(
        CardFan.resolveSwipeTarget(
          center: 0,
          count: 3,
          dragX: 500,
          stepPx: step,
          velocityDx: 3000,
        ),
        0,
      );
    });
  });

  testWidgets('focused: swiping past the last card clamps and stays put', (
    tester,
  ) async {
    int? focusedIndex;
    await _pump(
      tester,
      CardFan(
        cards: _cards(3),
        focused: true,
        centerIndex: 2,
        onFocusCard: (i) => focusedIndex = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CardFan), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(focusedIndex, isNull);
  });

  testWidgets('collapsed: horizontal drag does not re-center', (tester) async {
    int? focusedIndex;
    await _pump(
      tester,
      CardFan(
        cards: _cards(3),
        focused: false,
        centerIndex: 1,
        onFocusCard: (i) => focusedIndex = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CardFan),
      const Offset(-160, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(focusedIndex, isNull);
  });
}

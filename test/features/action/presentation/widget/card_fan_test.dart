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
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, child: fan),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all cards and empty state', (tester) async {
    await _pump(
        tester, CardFan(cards: _cards(3), focused: false, centerIndex: 1));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      expect(find.text('动作$i'), findsOneWidget);
    }

    await _pump(
        tester, const CardFan(cards: [], focused: false, centerIndex: 0));
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

  testWidgets('focused: tapping a side card requests re-centering',
      (tester) async {
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
}

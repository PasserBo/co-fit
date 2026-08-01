import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/domain/entity/action_deck.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/presentation/widget/deck_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ActionTemplateCard _card(String id, int durationSec) => ActionTemplateCard(
      id: id,
      name: id,
      type: ActionType.core,
      rawType: 'core',
      source: ActionSource.official,
      ablyActionId: id,
      defaultDurationSec: durationSec,
    );

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
  final cards = {'a': _card('a', 600), 'b': _card('b', 180)};
  const deck = ActionDeck(id: 'd1', name: '晨间唤醒', cardIds: ['a', 'b', 'ghost']);

  testWidgets('shows deck meta with count from cardIds and estimated minutes',
      (tester) async {
    await _pump(tester, DeckListBody(decks: const [deck], cardsById: cards));

    expect(find.text('晨间唤醒'), findsOneWidget);
    // 张数按 cardIds 全量(3),时长只按可关联卡估算(10+3 min)
    expect(find.text('3 张 · 约 13 min'), findsOneWidget);
  });

  testWidgets('expanded deck shows resolvable thumbs and add tile',
      (tester) async {
    ActionDeck? added;
    await _pump(
      tester,
      DeckListBody(
        decks: const [deck],
        cardsById: cards,
        expandedDeckId: 'd1',
        onAddCard: (d) => added = d,
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    expect(added?.id, 'd1');
  });

  testWidgets('tapping a row fires onDeckTap', (tester) async {
    ActionDeck? tapped;
    await _pump(
      tester,
      DeckListBody(
        decks: const [deck],
        cardsById: cards,
        onDeckTap: (d) => tapped = d,
      ),
    );

    await tester.tap(find.text('晨间唤醒'));
    expect(tapped?.id, 'd1');
  });

  testWidgets('shows empty state when there are no decks', (tester) async {
    await _pump(tester, const DeckListBody(decks: [], cardsById: {}));

    expect(find.text('还没有牌组'), findsOneWidget);
  });
}

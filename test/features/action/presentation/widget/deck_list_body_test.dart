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

  testWidgets('active deck shows 使用中 badge, others do not', (tester) async {
    await _pump(
      tester,
      DeckListBody(
        decks: const [
          deck,
          ActionDeck(id: 'd2', name: '午后燃脂', cardIds: ['a']),
        ],
        cardsById: cards,
        activeDeckId: 'd1',
      ),
    );

    expect(find.text('使用中'), findsOneWidget);
  });

  testWidgets('empty deck row shows amber guide text', (tester) async {
    await _pump(
      tester,
      DeckListBody(
        decks: const [ActionDeck(id: 'd3', name: '拉伸放松', cardIds: [])],
        cardsById: cards,
      ),
    );

    expect(find.text('空组 · 去加第一张卡 ›'), findsOneWidget);
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

  testWidgets('deck menu exposes setActive/rename/delete', (tester) async {
    final actions = <DeckMenuAction>[];
    await _pump(
      tester,
      DeckListBody(
        decks: const [deck],
        cardsById: cards,
        onDeckMenuAction: (_, action) => actions.add(action),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('设为当前使用'), findsOneWidget);
    expect(find.text('重命名'), findsOneWidget);
    await tester.tap(find.text('删除牌组'));
    await tester.pumpAndSettle();
    expect(actions, [DeckMenuAction.delete]);
  });

  testWidgets('create row fires onCreateDeck; empty state keeps it',
      (tester) async {
    var created = 0;
    await _pump(
      tester,
      DeckListBody(
        decks: const [],
        cardsById: const {},
        onCreateDeck: () => created++,
      ),
    );

    expect(find.text('还没有牌组 — 新建一组,把常练的动作放在一起'), findsOneWidget);
    await tester.tap(find.text('新建牌组'));
    expect(created, 1);
  });
}

import 'package:cofit/features/action/data/in_memory_action_deck_repository.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:flutter_test/flutter_test.dart';

ActionTemplateCard _card(String id) => ActionTemplateCard(
      id: id,
      name: id,
      type: ActionType.strength,
      rawType: 'strength',
      source: ActionSource.official,
      ablyActionId: id,
      defaultDurationSec: 600,
    );

void main() {
  test('seeds sample decks from provided cards', () async {
    final repo = InMemoryActionDeckRepository(
      seedCards: [for (var i = 0; i < 4; i++) _card('c$i')],
    );

    final decks = await repo.getDecks();
    expect(decks, hasLength(3));
    expect(decks.first.name, '考研自习室');
    expect(decks.first.cardIds, hasLength(5));
    // 所有引用都指向真实存在的卡
    for (final deck in decks) {
      for (final id in deck.cardIds) {
        expect(id, matches(RegExp('^c[0-3]\$')));
      }
    }
  });

  test('active deck defaults to first deck and can be switched', () async {
    final repo = InMemoryActionDeckRepository(seedCards: [_card('c0')]);

    expect(await repo.getActiveDeckId(), 'deck_1');

    await repo.setActiveDeckId('deck_2');
    expect(await repo.getActiveDeckId(), 'deck_2');

    await repo.setActiveDeckId('nonexistent');
    expect(await repo.getActiveDeckId(), 'deck_2');
  });

  test('returns no decks when there are no cards', () async {
    final repo = InMemoryActionDeckRepository();

    expect(await repo.getDecks(), isEmpty);
    expect(await repo.getActiveDeckId(), isNull);
  });
}

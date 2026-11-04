import 'package:cofit/features/action/data/in_memory_action_deck_repository.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/usecase/seed_default_decks_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

List<ActionTemplateCard> _cards(int count) {
  return List.generate(
    count,
    (i) => ActionTemplateCard(
      id: 'card-$i',
      name: '动作 $i',
      type: ActionType.strength,
      rawType: 'strength',
      source: ActionSource.official,
      ablyActionId: 'action-$i',
      defaultDurationSec: 60,
    ),
  );
}

void main() {
  _ssotTests();
  test('seeds 3 decks and sets active deck on empty repository', () async {
    final repository = InMemoryActionDeckRepository();
    final usecase = SeedDefaultDecksUsecase(repository);

    await usecase.execute(cards: _cards(6));

    final decks = await repository.getDecks();
    expect(decks, hasLength(3));
    expect(decks.map((d) => d.id), ['deck_1', 'deck_2', 'deck_3']);
    expect(await repository.getActiveDeckId(), 'deck_1');
  });

  test('is idempotent: second run does not duplicate decks', () async {
    final repository = InMemoryActionDeckRepository();
    final usecase = SeedDefaultDecksUsecase(repository);

    await usecase.execute(cards: _cards(6));
    await usecase.execute(cards: _cards(6));

    expect(await repository.getDecks(), hasLength(3));
  });

  test('does nothing without template cards', () async {
    final repository = InMemoryActionDeckRepository();
    final usecase = SeedDefaultDecksUsecase(repository);

    await usecase.execute(cards: const []);

    expect(await repository.getDecks(), isEmpty);
  });

  test('does not overwrite existing user decks', () async {
    final repository = InMemoryActionDeckRepository(seedCards: _cards(4));
    final usecase = SeedDefaultDecksUsecase(repository);
    final before = await repository.getDecks();

    await usecase.execute(cards: _cards(6));

    expect(await repository.getDecks(), before);
  });
}

void _ssotTests() {
  ActionTemplateCard card(String id) => ActionTemplateCard(
        id: id,
        name: id,
        type: ActionType.strength,
        rawType: 'strength',
        ablyActionId: id,
        defaultDurationSec: 60,
      );

  test('uses SSOT template ids when present and skips missing ones', () async {
    final repository = InMemoryActionDeckRepository();
    final usecase = SeedDefaultDecksUsecase(repository);
    // 自习室 5 张只上线了 3 张;碎片时间 3 张全在;晨间唤醒只剩 squat 一张
    final cards = [
      'neck_stretch', 'calf_raise', 'breathing', 'squat', 'plank', 'march',
      'other_a', 'other_b',
    ].map(card).toList();

    await usecase.execute(cards: cards);

    final decks = await repository.getDecks();
    expect(decks[0].cardIds, ['neck_stretch', 'calf_raise', 'breathing']);
    expect(decks[1].cardIds, ['squat']);
    expect(decks[2].cardIds, ['squat', 'plank', 'march']);
  });

  test('falls back to index picking when no SSOT id exists (legacy set)',
      () async {
    final repository = InMemoryActionDeckRepository();
    final usecase = SeedDefaultDecksUsecase(repository);
    final cards = ['a', 'b', 'c', 'd', 'e', 'f'].map(card).toList();

    await usecase.execute(cards: cards);

    final decks = await repository.getDecks();
    expect(decks.map((d) => d.cardIds.length), [5, 4, 3]);
  });
}

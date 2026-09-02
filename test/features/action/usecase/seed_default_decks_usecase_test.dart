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

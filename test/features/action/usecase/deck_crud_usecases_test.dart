import 'package:cofit/features/action/data/in_memory_action_deck_repository.dart';
import 'package:cofit/features/action/domain/entity/action_deck.dart';
import 'package:cofit/features/action/usecase/create_deck_usecase.dart';
import 'package:cofit/features/action/usecase/delete_deck_usecase.dart';
import 'package:cofit/features/action/usecase/update_deck_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateDeckUsecase', () {
    test('creates deck with trimmed name and uuid id', () async {
      final repository = InMemoryActionDeckRepository();
      final usecase = CreateDeckUsecase(repository);

      final deck = await usecase.execute(name: '  晨间唤醒  ', cardIds: ['c1']);

      expect(deck.name, '晨间唤醒');
      expect(deck.cardIds, ['c1']);
      expect(deck.id, isNotEmpty);
      expect(await repository.getDecks(), hasLength(1));
    });

    test('rejects empty or over-long names', () async {
      final usecase = CreateDeckUsecase(InMemoryActionDeckRepository());

      await expectLater(usecase.execute(name: '   '), throwsArgumentError);
      await expectLater(
        usecase.execute(name: 'x' * (CreateDeckUsecase.nameMaxLength + 1)),
        throwsArgumentError,
      );
    });
  });

  group('UpdateDeckUsecase', () {
    test('overwrites name and cardIds', () async {
      final repository = InMemoryActionDeckRepository();
      await repository.createDeck(
        const ActionDeck(id: 'd1', name: '旧名', cardIds: ['a']),
      );
      final usecase = UpdateDeckUsecase(repository);

      await usecase.execute(
        const ActionDeck(id: 'd1', name: '新名', cardIds: ['a', 'b', 'a']),
      );

      final decks = await repository.getDecks();
      expect(decks.single.name, '新名');
      expect(decks.single.cardIds, ['a', 'b', 'a']);
    });

    test('rejects unknown deck id', () async {
      final usecase = UpdateDeckUsecase(InMemoryActionDeckRepository());

      await expectLater(
        usecase.execute(const ActionDeck(id: 'nope', name: 'x', cardIds: [])),
        throwsStateError,
      );
    });
  });

  group('DeleteDeckUsecase', () {
    test('deleting active deck moves active to first remaining', () async {
      final repository = InMemoryActionDeckRepository();
      await repository.createDeck(
        const ActionDeck(id: 'd1', name: 'A', cardIds: []),
      );
      await repository.createDeck(
        const ActionDeck(id: 'd2', name: 'B', cardIds: []),
      );
      await repository.setActiveDeckId('d1');
      final usecase = DeleteDeckUsecase(repository);

      await usecase.execute(deckId: 'd1');

      expect(await repository.getDecks(), hasLength(1));
      expect(await repository.getActiveDeckId(), 'd2');
    });

    test('deleting the last deck clears active id', () async {
      final repository = InMemoryActionDeckRepository();
      await repository.createDeck(
        const ActionDeck(id: 'd1', name: 'A', cardIds: []),
      );
      final usecase = DeleteDeckUsecase(repository);

      await usecase.execute(deckId: 'd1');

      expect(await repository.getDecks(), isEmpty);
      expect(await repository.getActiveDeckId(), isNull);
    });

    test('deleting a non-active deck keeps active untouched', () async {
      final repository = InMemoryActionDeckRepository();
      await repository.createDeck(
        const ActionDeck(id: 'd1', name: 'A', cardIds: []),
      );
      await repository.createDeck(
        const ActionDeck(id: 'd2', name: 'B', cardIds: []),
      );
      await repository.setActiveDeckId('d1');
      final usecase = DeleteDeckUsecase(repository);

      await usecase.execute(deckId: 'd2');

      expect(await repository.getActiveDeckId(), 'd1');
    });
  });
}

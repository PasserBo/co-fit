import 'package:cofit/features/action/data/in_memory_action_deck_repository.dart';
import 'package:cofit/features/action/data/in_memory_custom_card_repository.dart';
import 'package:cofit/features/action/domain/entity/action_deck.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/usecase/create_custom_card_usecase.dart';
import 'package:cofit/features/action/usecase/delete_custom_card_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateCustomCardUsecase', () {
    test('creates a custom card with type mapping and default ablyActionId',
        () async {
      final repository = InMemoryCustomCardRepository();
      final usecase = CreateCustomCardUsecase(repository);

      final card = await usecase.execute(
        name: ' 开合跳 ',
        rawType: 'cardio',
        durationSec: 45,
      );

      expect(card.name, '开合跳');
      expect(card.type, ActionType.cardio);
      expect(card.rawType, 'cardio');
      expect(card.source, ActionSource.custom);
      expect(card.ablyActionId, 'cardio');
      expect(card.defaultDurationSec, 45);
      expect(await repository.getCustomCards(), hasLength(1));
    });

    test('rejects invalid inputs', () async {
      final usecase = CreateCustomCardUsecase(InMemoryCustomCardRepository());

      await expectLater(
        usecase.execute(name: ' ', rawType: 'cardio', durationSec: 30),
        throwsArgumentError,
      );
      await expectLater(
        usecase.execute(name: '卡', rawType: ' ', durationSec: 30),
        throwsArgumentError,
      );
      await expectLater(
        usecase.execute(name: '卡', rawType: 'cardio', durationSec: 0),
        throwsArgumentError,
      );
    });
  });

  group('DeleteCustomCardUsecase', () {
    test('deletes card and strips it from all decks', () async {
      final cardRepository = InMemoryCustomCardRepository();
      final deckRepository = InMemoryActionDeckRepository();
      final create = CreateCustomCardUsecase(cardRepository);
      final card = await create.execute(
        name: '开合跳',
        rawType: 'cardio',
        durationSec: 45,
      );
      await deckRepository.createDeck(
        ActionDeck(id: 'd1', name: 'A', cardIds: ['x', card.id, 'y', card.id]),
      );
      await deckRepository.createDeck(
        const ActionDeck(id: 'd2', name: 'B', cardIds: ['z']),
      );
      final usecase = DeleteCustomCardUsecase(cardRepository, deckRepository);

      await usecase.execute(cardId: card.id);

      expect(await cardRepository.getCustomCards(), isEmpty);
      final decks = await deckRepository.getDecks();
      expect(decks.firstWhere((d) => d.id == 'd1').cardIds, ['x', 'y']);
      expect(decks.firstWhere((d) => d.id == 'd2').cardIds, ['z']);
    });
  });
}

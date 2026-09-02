import '../domain/action_deck_repository.dart';
import '../domain/custom_card_repository.dart';

/// 删除自建卡,并把它从所有牌组里摘除(避免牌组残留悬空引用)。
class DeleteCustomCardUsecase {
  DeleteCustomCardUsecase(this._cardRepository, this._deckRepository);

  final CustomCardRepository _cardRepository;
  final ActionDeckRepository _deckRepository;

  Future<void> execute({required String cardId}) async {
    final trimmed = cardId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(cardId, 'cardId', 'cardId must not be empty.');
    }

    await _cardRepository.deleteCard(trimmed);

    final decks = await _deckRepository.getDecks();
    for (final deck in decks) {
      if (!deck.cardIds.contains(trimmed)) {
        continue;
      }
      final nextCardIds =
          deck.cardIds.where((id) => id != trimmed).toList(growable: false);
      await _deckRepository.updateDeck(deck.copyWith(cardIds: nextCardIds));
    }
  }
}

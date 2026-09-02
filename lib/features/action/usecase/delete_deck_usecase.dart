import '../domain/action_deck_repository.dart';

/// 删除牌组。若删的是当前使用中的牌组,active 顺移到剩余第一组(无剩余则清除)。
class DeleteDeckUsecase {
  DeleteDeckUsecase(this._repository);

  final ActionDeckRepository _repository;

  Future<void> execute({required String deckId}) async {
    final trimmed = deckId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(deckId, 'deckId', 'deckId must not be empty.');
    }

    final wasActive = await _repository.getActiveDeckId() == trimmed;
    await _repository.deleteDeck(trimmed);

    if (wasActive) {
      final remaining = await _repository.getDecks();
      await _repository.setActiveDeckId(
        remaining.isEmpty ? null : remaining.first.id,
      );
    }
  }
}

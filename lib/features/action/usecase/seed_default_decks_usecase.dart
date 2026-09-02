import '../domain/action_deck_repository.dart';
import '../domain/entity/action_deck.dart';
import '../domain/entity/action_template_card.dart';

/// 首启种子牌组(与旧 in-memory stub 的播种规则一致)。
/// 幂等:已有任何牌组则不再播种;固定 deck id,重复执行只是覆盖同名种子。
class SeedDefaultDecksUsecase {
  SeedDefaultDecksUsecase(this._repository);

  static const _seedNames = ['考研自习室', '晨间唤醒', '碎片时间'];
  static const _seedSizes = [5, 4, 3];

  final ActionDeckRepository _repository;

  Future<void> execute({required List<ActionTemplateCard> cards}) async {
    if (cards.isEmpty) {
      return;
    }
    final existing = await _repository.getDecks();
    if (existing.isNotEmpty) {
      return;
    }

    for (var i = 0; i < _seedNames.length; i++) {
      final cardIds = List.generate(
        _seedSizes[i],
        (j) => cards[(i * 2 + j) % cards.length].id,
      );
      await _repository.createDeck(
        ActionDeck(
          id: 'deck_${i + 1}',
          name: _seedNames[i],
          cardIds: cardIds,
        ),
      );
    }

    final activeDeckId = await _repository.getActiveDeckId();
    if (activeDeckId == null) {
      await _repository.setActiveDeckId('deck_1');
    }
  }
}

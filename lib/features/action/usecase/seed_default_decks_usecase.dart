import '../domain/action_deck_repository.dart';
import '../domain/entity/action_deck.dart';
import '../domain/entity/action_template_card.dart';

/// 首启种子牌组。幂等:已有任何牌组则不再播种;固定 deck id。
/// 按 SSOT 模板 id 指定(docs/default_card_templates.md §4);线上缺卡时跳过该 id,
/// 一张都没有(老模板集)则退回按下标取卡的旧规则。
class SeedDefaultDecksUsecase {
  SeedDefaultDecksUsecase(this._repository);

  static const _seedNames = ['考研自习室', '晨间唤醒', '碎片时间'];
  static const _seedSizes = [5, 4, 3];
  static const seedCardIds = [
    ['neck_stretch', 'side_bend', 'calf_raise', 'wall_sit', 'breathing'],
    ['cat_cow', 'jumping_jack', 'squat', 'forward_fold'],
    ['squat', 'plank', 'march'],
  ];

  final ActionDeckRepository _repository;

  Future<void> execute({required List<ActionTemplateCard> cards}) async {
    if (cards.isEmpty) {
      return;
    }
    final existing = await _repository.getDecks();
    if (existing.isNotEmpty) {
      return;
    }

    final available = cards.map((c) => c.id).toSet();
    for (var i = 0; i < _seedNames.length; i++) {
      var cardIds =
          seedCardIds[i].where(available.contains).toList(growable: false);
      if (cardIds.isEmpty) {
        cardIds = List.generate(
          _seedSizes[i],
          (j) => cards[(i * 2 + j) % cards.length].id,
        );
      }
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

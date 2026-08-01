import '../domain/action_deck_repository.dart';
import '../domain/entity/action_deck.dart';
import '../domain/entity/action_template_card.dart';

/// G3 stub:内存牌组仓库。
/// 用真实模板卡的 id 播种示例牌组,保证 UI 能关联出卡片;无卡时返回空列表。
class InMemoryActionDeckRepository implements ActionDeckRepository {
  InMemoryActionDeckRepository({List<ActionTemplateCard> seedCards = const []})
      : _decks = _seedDecks(seedCards) {
    _activeDeckId = _decks.isEmpty ? null : _decks.first.id;
  }

  static const _seedNames = ['考研自习室', '晨间唤醒', '碎片时间'];
  static const _seedSizes = [5, 4, 3];

  final List<ActionDeck> _decks;
  String? _activeDeckId;

  static List<ActionDeck> _seedDecks(List<ActionTemplateCard> cards) {
    if (cards.isEmpty) {
      return const [];
    }
    return List.generate(_seedNames.length, (i) {
      final cardIds = List.generate(
        _seedSizes[i],
        (j) => cards[(i * 2 + j) % cards.length].id,
      );
      return ActionDeck(
        id: 'deck_${i + 1}',
        name: _seedNames[i],
        cardIds: cardIds,
      );
    });
  }

  @override
  Future<List<ActionDeck>> getDecks() async => List.unmodifiable(_decks);

  @override
  Future<String?> getActiveDeckId() async => _activeDeckId;

  @override
  Future<void> setActiveDeckId(String deckId) async {
    if (_decks.any((deck) => deck.id == deckId)) {
      _activeDeckId = deckId;
    }
  }
}

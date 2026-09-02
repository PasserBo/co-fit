import 'entity/action_deck.dart';

/// 牌组仓库。云端实现:users/{uid}/decks + users/{uid}.activeDeckId(A2);
/// in-memory 实现保留给测试/widgetbook。
abstract class ActionDeckRepository {
  Future<List<ActionDeck>> getDecks();

  Future<void> createDeck(ActionDeck deck);

  /// 覆盖 name/cardIds(按 deck.id 定位;不存在时实现可抛错)。
  Future<void> updateDeck(ActionDeck deck);

  Future<void> deleteDeck(String deckId);

  /// 「当前使用中」牌组 —— P4 扇形手牌/牌组切换(#4a)依赖;无牌组时为 null。
  Future<String?> getActiveDeckId();

  /// 传 null 清除(如删除了当前使用中的牌组且无剩余牌组)。
  Future<void> setActiveDeckId(String? deckId);
}

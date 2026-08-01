import 'entity/action_deck.dart';

/// 牌组仓库(G3 stub 阶段,将来换 Firestore 实现:users/{uid}/decks + users/{uid}.activeDeckId)。
abstract class ActionDeckRepository {
  Future<List<ActionDeck>> getDecks();

  /// 「当前使用中」牌组 —— P4 扇形手牌/牌组切换(#4a)依赖;无牌组时为 null。
  Future<String?> getActiveDeckId();

  Future<void> setActiveDeckId(String deckId);
}

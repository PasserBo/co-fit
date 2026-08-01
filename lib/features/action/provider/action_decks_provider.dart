import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/action_deck.dart';
import 'action_deck_repository_provider.dart';

final actionDecksProvider = FutureProvider<List<ActionDeck>>((ref) {
  return ref.watch(actionDeckRepositoryProvider).getDecks();
});

/// 「当前使用中」牌组 id(扇形手牌/#4a 切换用)。
final activeDeckIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(actionDeckRepositoryProvider).getActiveDeckId();
});

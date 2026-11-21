import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/action_deck.dart';
import '../domain/entity/action_template_card.dart';
import '../presentation/action_template_usecase_provider.dart';
import 'action_deck_repository_provider.dart';

final actionDecksProvider = FutureProvider<List<ActionDeck>>((ref) async {
  // 首启幂等播种(空牌组 + 有模板卡时才生效)。
  final cards =
      ref.watch(templateCardsProvider).value ?? const <ActionTemplateCard>[];
  await ref.watch(seedDefaultDecksUsecaseProvider).execute(cards: cards);
  return ref.watch(actionDeckRepositoryProvider).getDecks();
});

/// 「当前使用中」牌组 id(扇形手牌/#4a 切换用)。
final activeDeckIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(actionDeckRepositoryProvider).getActiveDeckId();
});

/// 当前使用中的牌组:按 [activeDeckIdProvider] 找;找不到则取第一个;没有牌组为 null。
final activeDeckProvider = Provider<ActionDeck?>((ref) {
  final decks = ref.watch(actionDecksProvider).value ?? const <ActionDeck>[];
  final activeId = ref.watch(activeDeckIdProvider).value;
  for (final deck in decks) {
    if (deck.id == activeId) {
      return deck;
    }
  }
  return decks.isEmpty ? null : decks.first;
});

/// 当前手牌:使用中牌组里、仍然存在的卡,按牌组顺序。
final activeHandProvider = Provider<List<ActionTemplateCard>>((ref) {
  final cards =
      ref.watch(templateCardsProvider).value ?? const <ActionTemplateCard>[];
  final byId = {for (final card in cards) card.id: card};
  return [
    for (final id in ref.watch(activeDeckProvider)?.cardIds ?? const <String>[])
      if (byId[id] != null) byId[id]!,
  ];
});

/// 手牌数据是否还在加载(牌组或卡片任一未就绪)。
final activeHandLoadingProvider = Provider<bool>((ref) {
  return ref.watch(actionDecksProvider).isLoading ||
      ref.watch(templateCardsProvider).isLoading;
});

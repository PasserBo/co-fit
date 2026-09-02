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

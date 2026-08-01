import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_action_deck_repository.dart';
import '../domain/action_deck_repository.dart';
import '../domain/entity/action_template_card.dart';
import '../presentation/action_template_usecase_provider.dart';

/// DI:牌组仓库(G3 stub)。用已加载的模板卡播种示例牌组;
/// 将来换 Firestore 实现时只改这里。
final actionDeckRepositoryProvider = Provider<ActionDeckRepository>((ref) {
  final cards =
      ref.watch(templateCardsProvider).value ?? const <ActionTemplateCard>[];
  return InMemoryActionDeckRepository(seedCards: cards);
});

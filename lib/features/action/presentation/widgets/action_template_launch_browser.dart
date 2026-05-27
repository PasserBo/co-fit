import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entity/action_template_card.dart';
import '../action_template_usecase_provider.dart';
import 'action_template_card_item.dart';

class ActionTemplateLaunchBrowser extends ConsumerWidget {
  const ActionTemplateLaunchBrowser({
    required this.templateCardsState,
    required this.isStartingTemplateAction,
    required this.startingTemplateId,
    required this.onUseTemplateCard,
    required this.formatDuration,
    super.key,
  });

  final AsyncValue<List<ActionTemplateCard>> templateCardsState;
  final bool isStartingTemplateAction;
  final String? startingTemplateId;
  final void Function(ActionTemplateCard card) onUseTemplateCard;
  final String Function(int durationSec) formatDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模板卡启动', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            const Text('点击“使用这张卡”会发送 action_started 事件。'),
            const SizedBox(height: 12),
            templateCardsState.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '模板卡加载失败: $error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(templateCardsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试加载'),
                  ),
                ],
              ),
              data: (cards) {
                if (cards.isEmpty) {
                  return const Text('暂无模板卡');
                }
                return Column(
                  children: cards.map((card) {
                    final isStartingThisCard =
                        isStartingTemplateAction && startingTemplateId == card.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionTemplateCardItem(
                        card: card,
                        durationLabel: formatDuration(card.defaultDurationSec),
                        isBusy: isStartingThisCard || isStartingTemplateAction,
                        onUseCard: () => onUseTemplateCard(card),
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entity/action_template_card.dart';

class ActionTemplateCardItem extends StatelessWidget {
  const ActionTemplateCardItem({
    required this.card,
    required this.durationLabel,
    required this.isBusy,
    required this.onUseCard,
    super.key,
  });

  final ActionTemplateCard card;
  final String durationLabel;
  final bool isBusy;
  final VoidCallback onUseCard;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('类型: ${card.type} · 时长: $durationLabel'),
                  if (card.intensityLabel.isNotEmpty)
                    Text('强度建议: ${card.intensityLabel}'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isBusy ? null : onUseCard,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('使用这张卡'),
            ),
          ],
        ),
      ),
    );
  }
}

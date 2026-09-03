import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/dashed_border.dart';
import '../../domain/entity/action_deck.dart';
import '../../domain/entity/action_template_card.dart';
import '../../provider/action_deck_repository_provider.dart';
import '../../provider/action_decks_provider.dart';
import '../action_template_usecase_provider.dart';
import '../widget/action_type_style.dart';
import '../widget/deck_name_dialog.dart';
import 'deck_add_cards_sheet_view.dart';

/// 牌组详情(#15b,push):标题即改名入口(✎);
/// 卡列表按 cardIds 顺序,拖柄排序;同卡重复带「第 N 次」,移除按索引;
/// 底部虚线加卡 → 加卡 sheet(#15c)。
class DeckDetailPageView extends ConsumerWidget {
  const DeckDetailPageView({required this.deckId, super.key});

  final String deckId;

  Future<void> _saveCardIds(
    BuildContext context,
    WidgetRef ref,
    ActionDeck deck,
    List<String> nextCardIds,
  ) async {
    try {
      await ref
          .read(updateDeckUsecaseProvider)
          .execute(deck.copyWith(cardIds: nextCardIds));
      ref.invalidate(actionDecksProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('保存失败:$error')));
      }
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ActionDeck deck,
  ) async {
    final name = await showDeckNameDialog(
      context,
      title: '重命名牌组',
      confirmLabel: '保存',
      initialName: deck.name,
    );
    if (name == null || name == deck.name || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(updateDeckUsecaseProvider)
          .execute(deck.copyWith(name: name));
      ref.invalidate(actionDecksProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('重命名失败:$error')));
      }
    }
  }

  Future<void> _addCards(
    BuildContext context,
    WidgetRef ref,
    ActionDeck deck,
  ) async {
    final pickedIds = await DeckAddCardsSheetView.show(context);
    if (pickedIds == null || pickedIds.isEmpty || !context.mounted) {
      return;
    }
    await _saveCardIds(context, ref, deck, [...deck.cardIds, ...pickedIds]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final decks = ref.watch(actionDecksProvider).value;
    final activeDeckId = ref.watch(activeDeckIdProvider).value;
    final cards =
        ref.watch(templateCardsProvider).value ?? const <ActionTemplateCard>[];
    final cardsById = {for (final card in cards) card.id: card};

    ActionDeck? deck;
    for (final candidate in decks ?? const <ActionDeck>[]) {
      if (candidate.id == deckId) {
        deck = candidate;
        break;
      }
    }

    // 牌组被删除(如另一设备)→ 回列表。
    if (decks != null && deck == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    if (deck == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentDeck = deck;

    final deckCards = [
      for (final id in currentDeck.cardIds) cardsById[id],
    ];
    final totalMinutes = deckCards.fold<int>(
      0,
      (sum, card) =>
          sum + ((card?.defaultDurationSec ?? 0) / 60).round(),
    );

    // 「第 N 次」标注:同 id 在此索引前出现的次数 + 1
    final occurrence = <int>[];
    final seen = <String, int>{};
    for (final id in currentDeck.cardIds) {
      final next = (seen[id] ?? 0) + 1;
      seen[id] = next;
      occurrence.add(next);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => _rename(context, ref, currentDeck),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CoFitDimens.spacingSm,
            children: [
              Flexible(
                child: Text(
                  currentDeck.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: CoFitDimens.sizeCardIcon,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
        actions: [
          if (currentDeck.id == activeDeckId)
            Padding(
              padding: const EdgeInsets.only(right: CoFitDimens.spacingLg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoFitDimens.spacingMd,
                  vertical: CoFitDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.primarySubtle,
                  borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
                  border: Border.all(
                    color: colors.primaryBorder,
                    width: CoFitDimens.borderWidthHairline,
                  ),
                ),
                child: Text(
                  '使用中',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primaryMain,
                    fontWeight: CoFitFontWeights.label,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CoFitDimens.spacingLg,
                0,
                CoFitDimens.spacingLg,
                CoFitDimens.spacingSm,
              ),
              child: Text(
                '${currentDeck.cardIds.length} 张 · 约 $totalMinutes min · 长按拖动排序',
                style:
                    textTheme.bodySmall?.copyWith(color: colors.textTertiary),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(
                  CoFitDimens.spacingLg,
                  0,
                  CoFitDimens.spacingLg,
                  CoFitDimens.spacingLg,
                ),
                itemCount: currentDeck.cardIds.length,
                footer: Padding(
                  padding:
                      const EdgeInsets.only(top: CoFitDimens.spacingSm),
                  child: _AddCardRow(
                    onTap: () => _addCards(context, ref, currentDeck),
                  ),
                ),
                onReorder: (oldIndex, newIndex) {
                  final next = [...currentDeck.cardIds];
                  final moved = next.removeAt(oldIndex);
                  next.insert(
                    newIndex > oldIndex ? newIndex - 1 : newIndex,
                    moved,
                  );
                  _saveCardIds(context, ref, currentDeck, next);
                },
                itemBuilder: (context, index) {
                  final card = cardsById[currentDeck.cardIds[index]];
                  return Padding(
                    key: ValueKey('deck-card-$index-${currentDeck.cardIds[index]}'),
                    padding:
                        const EdgeInsets.only(bottom: CoFitDimens.spacingSm),
                    child: _DeckCardRow(
                      index: index,
                      card: card,
                      occurrence: occurrence[index],
                      onRemove: () {
                        final next = [...currentDeck.cardIds]..removeAt(index);
                        _saveCardIds(context, ref, currentDeck, next);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCardRow extends StatelessWidget {
  const _DeckCardRow({
    required this.index,
    required this.card,
    required this.occurrence,
    required this.onRemove,
  });

  final int index;

  /// null = 卡模板已不存在(如自建卡被删后残留;正常流程会同步移除)。
  final ActionTemplateCard? card;
  final int occurrence;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final typeColor = card?.type.mainOf(colors) ?? colors.statusIdle;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingMd,
        vertical: CoFitDimens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Row(
        spacing: CoFitDimens.spacingMd,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle_rounded,
              size: CoFitDimens.sizeCardIconBlock,
              color: colors.textDisabled,
            ),
          ),
          Container(
            width: CoFitDimens.sizeCardTypeBar,
            height: CoFitDimens.sizeTypeBarHeight,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        card?.name ?? '已删除的卡片',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: CoFitFontWeights.heading,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (occurrence > 1) ...[
                      const SizedBox(width: CoFitDimens.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoFitDimens.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.typeStrengthSubtle,
                          borderRadius:
                              BorderRadius.circular(CoFitDimens.radiusSm),
                        ),
                        child: Text(
                          '第 $occurrence 次',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.typeStrength,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (card != null)
                  Text(
                    '${card!.type.label} · '
                    '${(card!.defaultDurationSec / 60).round().clamp(1, 999)} min',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: CoFitDimens.sizeMinTapTarget,
            height: CoFitDimens.sizeMinTapTarget,
            child: IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                size: CoFitDimens.sizeCheckBadge,
                color: colors.statusDanger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCardRow extends StatelessWidget {
  const _AddCardRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DashedBorder(
        color: colors.primaryBorder,
        radius: CoFitDimens.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(CoFitDimens.spacingMd),
          decoration: BoxDecoration(
            color: colors.primaryMain.withValues(alpha: CoFitOpacities.faint),
            borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: CoFitDimens.spacingSm,
            children: [
              Icon(
                Icons.add,
                size: CoFitDimens.sizeCardIcon,
                color: colors.primaryMain,
              ),
              Text(
                '加卡',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: CoFitFontWeights.heading,
                      color: colors.primaryMain,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

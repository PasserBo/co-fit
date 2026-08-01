import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_deck.dart';

/// 收起态牌组 chip(#6b 左下):当前牌组名 + ▾ 圆钮,点击开/收下拉。
class DeckChip extends StatelessWidget {
  const DeckChip({
    required this.deckName,
    required this.open,
    required this.onTap,
    super.key,
  });

  final String deckName;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingSm,
        children: [
          Text(
            deckName,
            style: textTheme.labelLarge?.copyWith(color: colors.primaryMain),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          AnimatedRotation(
            duration: kThemeAnimationDuration,
            turns: open ? 0.5 : 0,
            child: Container(
              width: CoFitDimens.sizeDockItem,
              height: CoFitDimens.sizeDockItem,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primarySubtle,
                border: Border.all(
                  color: colors.primaryBorder,
                  width: CoFitDimens.borderWidthHairline,
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: CoFitDimens.sizeCardIcon,
                color: colors.primaryMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 牌组下拉悬浮层(#6b/#4a):常用牌组若干行 + 「查看全部牌组」。
/// 悬浮在场景之上,不挤压布局(由外部用 Stack/Positioned 放置)。
class DeckPopover extends StatelessWidget {
  const DeckPopover({
    required this.decks,
    required this.activeDeckId,
    required this.onSelect,
    required this.onSeeAll,
    this.maxRows = 4,
    super.key,
  });

  final List<ActionDeck> decks;
  final String? activeDeckId;
  final ValueChanged<ActionDeck> onSelect;
  final VoidCallback onSeeAll;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final top = decks.take(maxRows).toList(growable: false);

    return Container(
      width: CoFitDimens.sizePopoverWidth,
      padding: const EdgeInsets.all(CoFitDimens.spacingXs),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.borderStrong,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final deck in top)
            _DeckRow(
              deck: deck,
              active: deck.id == activeDeckId,
              onTap: () => onSelect(deck),
            ),
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: CoFitDimens.spacingSm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.borderStrong,
                    width: CoFitDimens.borderWidthHairline,
                  ),
                ),
              ),
              child: Text(
                '查看全部牌组 →',
                textAlign: TextAlign.center,
                style:
                    textTheme.labelMedium?.copyWith(color: colors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.active, this.onTap});

  final ActionDeck deck;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final fg = active ? colors.primaryMain : colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CoFitDimens.spacingMd,
          vertical: CoFitDimens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: active ? colors.primarySubtle : null,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                deck.name,
                style: textTheme.labelLarge?.copyWith(color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              active ? '✓' : '${deck.cardIds.length} 张',
              style: textTheme.labelSmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/dashed_border.dart';
import '../../domain/entity/action_deck.dart';
import '../../domain/entity/action_template_card.dart';
import 'action_type_style.dart';

/// 「我的卡组」tab(README §3 + #11b 过程稿):
/// 每套牌组一行(叠牌缩略 + 名称 + 张数/约时长),点开就地展开组内迷你卡 + 加卡入口。
/// 纯展示:展开状态由外部持有。
class DeckListBody extends StatelessWidget {
  const DeckListBody({
    required this.decks,
    required this.cardsById,
    this.expandedDeckId,
    this.onDeckTap,
    this.onAddCard,
    super.key,
  });

  final List<ActionDeck> decks;

  /// 用于把 deck.cardIds 关联成卡片;缺失的 id 跳过(时长按可关联卡估算)。
  final Map<String, ActionTemplateCard> cardsById;
  final String? expandedDeckId;
  final ValueChanged<ActionDeck>? onDeckTap;
  final ValueChanged<ActionDeck>? onAddCard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    if (decks.isEmpty) {
      return Center(
        child: Text(
          '还没有牌组',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colors.textTertiary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(CoFitDimens.spacingLg),
      itemCount: decks.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: CoFitDimens.spacingMd),
      itemBuilder: (context, index) {
        final deck = decks[index];
        return _DeckRow(
          deck: deck,
          cards: [
            for (final id in deck.cardIds)
              if (cardsById[id] != null) cardsById[id]!,
          ],
          expanded: deck.id == expandedDeckId,
          onTap: onDeckTap == null ? null : () => onDeckTap!(deck),
          onAddCard: onAddCard == null ? null : () => onAddCard!(deck),
        );
      },
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({
    required this.deck,
    required this.cards,
    required this.expanded,
    this.onTap,
    this.onAddCard,
  });

  final ActionDeck deck;
  final List<ActionTemplateCard> cards;
  final bool expanded;
  final VoidCallback? onTap;
  final VoidCallback? onAddCard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final totalMinutes = cards.fold<int>(
      0,
      (sum, card) => sum + (card.defaultDurationSec / 60).round(),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: expanded ? colors.borderFocus : colors.borderSubtle,
          width: expanded
              ? CoFitDimens.borderWidthFocus
              : CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(CoFitDimens.spacingMd),
              child: Row(
                spacing: CoFitDimens.spacingMd,
                children: [
                  _DeckStack(
                    accent: cards.isEmpty
                        ? colors.statusIdle
                        : cards.first.type.mainOf(colors),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${deck.cardIds.length} 张 · 约 $totalMinutes min',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    color:
                        expanded ? colors.primaryMain : colors.textDisabled,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                CoFitDimens.spacingMd,
                0,
                CoFitDimens.spacingMd,
                CoFitDimens.spacingMd,
              ),
              child: IntrinsicHeight(
                child: Row(
                  spacing: CoFitDimens.spacingSm,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final card in cards) _DeckCardThumb(card: card),
                    _AddCardTile(onTap: onAddCard),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 叠牌缩略:两张中性「牌背」+ 一张主色牌面。位置由 token 尺寸推导。
class _DeckStack extends StatelessWidget {
  const _DeckStack({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    const cardW = CoFitDimens.sizeDeckStackCardWidth;
    const cardH = CoFitDimens.sizeDeckStackCardHeight;
    const slackX = CoFitDimens.sizeDeckStackWidth - cardW;
    const slackY = CoFitDimens.sizeDeckStackHeight - cardH;

    Widget miniCard(Color color, double tiltDeg) {
      return Transform.rotate(
        angle: tiltDeg * math.pi / 180,
        child: Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
          ),
        ),
      );
    }

    return SizedBox(
      width: CoFitDimens.sizeDeckStackWidth,
      height: CoFitDimens.sizeDeckStackHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: slackY / 2,
            child: miniCard(colors.borderSubtle, CoFitDecor.deckStackTiltBackDeg),
          ),
          Positioned(
            left: slackX / 2,
            top: slackY / 4,
            child: miniCard(colors.borderStrong, CoFitDecor.deckStackTiltMidDeg),
          ),
          Positioned(
            left: slackX,
            top: 0,
            child: miniCard(accent, 0),
          ),
        ],
      ),
    );
  }
}

class _DeckCardThumb extends StatelessWidget {
  const _DeckCardThumb({required this.card});

  final ActionTemplateCard card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: CoFitDimens.sizeDeckCardThumb,
      padding: const EdgeInsets.all(CoFitDimens.spacingSm),
      decoration: BoxDecoration(
        color: colors.bgDeep,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: CoFitDimens.sizeCardIcon,
            height: CoFitDimens.sizeCardIcon,
            decoration: BoxDecoration(
              color: card.type.mainOf(colors),
              borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
            ),
          ),
          const SizedBox(height: CoFitDimens.spacingXs),
          Text(
            card.name,
            style: textTheme.labelSmall
                ?.copyWith(fontWeight: CoFitFontWeights.heading),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: CoFitDimens.spacingXs),
          Text(
            '${(card.defaultDurationSec / 60).round().clamp(1, 999)}m',
            style: textTheme.labelSmall?.copyWith(color: colors.textDisabled),
          ),
        ],
      ),
    );
  }
}

class _AddCardTile extends StatelessWidget {
  const _AddCardTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: DashedBorder(
        color: colors.primaryBorder,
        radius: CoFitDimens.radiusMd,
        child: SizedBox(
          width: CoFitDimens.sizeDeckCardThumb,
          child: Center(
            child: Icon(
              Icons.add,
              size: CoFitDimens.sizeCardIcon,
              color: colors.primaryMain,
            ),
          ),
        ),
      ),
    );
  }
}

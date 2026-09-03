import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/dashed_border.dart';
import '../../domain/entity/action_deck.dart';
import '../../domain/entity/action_template_card.dart';
import 'action_type_style.dart';

/// 牌组行 ⋯ 菜单动作(#15a popover)。
enum DeckMenuAction { setActive, rename, delete }

/// 「我的卡组」tab(#15a 定稿):
/// 行 = 叠牌缩略 + 名称(+「使用中」徽章)+ 「N 张 · 约 X min」+ 行尾 ⋯ 菜单;
/// 空组行展示 amber 引导;底部虚线「新建牌组」;0 组 = 空态引导。
/// 纯展示:点行进详情、菜单动作、新建 全部经回调交给外部。
class DeckListBody extends StatelessWidget {
  const DeckListBody({
    required this.decks,
    required this.cardsById,
    this.activeDeckId,
    this.onDeckTap,
    this.onDeckMenuAction,
    this.onCreateDeck,
    super.key,
  });

  final List<ActionDeck> decks;

  /// 用于把 deck.cardIds 关联成卡片;缺失的 id 跳过(时长按可关联卡估算)。
  final Map<String, ActionTemplateCard> cardsById;
  final String? activeDeckId;
  final ValueChanged<ActionDeck>? onDeckTap;
  final void Function(ActionDeck deck, DeckMenuAction action)?
      onDeckMenuAction;
  final VoidCallback? onCreateDeck;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    if (decks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        children: [
          _CreateDeckRow(onTap: onCreateDeck),
          const SizedBox(height: CoFitDimens.spacingMd),
          Text(
            '还没有牌组 — 新建一组,把常练的动作放在一起',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(CoFitDimens.spacingLg),
      itemCount: decks.length + 1,
      separatorBuilder: (_, _) =>
          const SizedBox(height: CoFitDimens.spacingSm),
      itemBuilder: (context, index) {
        if (index == decks.length) {
          return _CreateDeckRow(onTap: onCreateDeck);
        }
        final deck = decks[index];
        return _DeckRow(
          deck: deck,
          cards: [
            for (final id in deck.cardIds)
              if (cardsById[id] != null) cardsById[id]!,
          ],
          isActive: deck.id == activeDeckId,
          onTap: onDeckTap == null ? null : () => onDeckTap!(deck),
          onMenuAction: onDeckMenuAction == null
              ? null
              : (action) => onDeckMenuAction!(deck, action),
        );
      },
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({
    required this.deck,
    required this.cards,
    required this.isActive,
    this.onTap,
    this.onMenuAction,
  });

  final ActionDeck deck;
  final List<ActionTemplateCard> cards;
  final bool isActive;
  final VoidCallback? onTap;
  final ValueChanged<DeckMenuAction>? onMenuAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final totalMinutes = cards.fold<int>(
      0,
      (sum, card) => sum + (card.defaultDurationSec / 60).round(),
    );
    final isEmptyDeck = deck.cardIds.isEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CoFitDimens.spacingMd,
          vertical: CoFitDimens.spacingMd,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
          border: Border.all(
            color: isActive ? colors.primaryBorder : colors.borderSubtle,
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
        child: Row(
          spacing: CoFitDimens.spacingMd,
          children: [
            _DeckStack(
              accent: cards.isEmpty
                  ? colors.statusIdle
                  : cards.first.type.mainOf(colors),
              isEmpty: isEmptyDeck,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          deck.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: CoFitFontWeights.heading,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: CoFitDimens.spacingSm),
                        const _ActiveBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: CoFitDimens.spacingXs / 2),
                  Text(
                    isEmptyDeck
                        ? '空组 · 去加第一张卡 ›'
                        : '${deck.cardIds.length} 张 · 约 $totalMinutes min',
                    style: textTheme.bodySmall?.copyWith(
                      color: isEmptyDeck
                          ? colors.statusPaused
                          : colors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _DeckMenuButton(onMenuAction: onMenuAction),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingXs,
        vertical: CoFitDimens.spacingXs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.primarySubtle,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
        border: Border.all(
          color: colors.primaryBorder,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Text(
        '使用中',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primaryMain,
              fontWeight: CoFitFontWeights.label,
            ),
      ),
    );
  }
}

class _DeckMenuButton extends StatelessWidget {
  const _DeckMenuButton({this.onMenuAction});

  final ValueChanged<DeckMenuAction>? onMenuAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return SizedBox(
      width: CoFitDimens.sizeMinTapTarget,
      height: CoFitDimens.sizeMinTapTarget,
      child: PopupMenuButton<DeckMenuAction>(
        enabled: onMenuAction != null,
        onSelected: onMenuAction,
        color: colors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
          side: BorderSide(
            color: colors.borderStrong,
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
        icon: Icon(Icons.more_horiz_rounded, color: colors.textTertiary),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: DeckMenuAction.setActive,
            child: Text('设为当前使用',
                style: TextStyle(color: colors.textPrimary)),
          ),
          PopupMenuItem(
            value: DeckMenuAction.rename,
            child: Text('重命名', style: TextStyle(color: colors.textPrimary)),
          ),
          PopupMenuItem(
            value: DeckMenuAction.delete,
            child: Text('删除牌组',
                style: TextStyle(color: colors.statusDanger)),
          ),
        ],
      ),
    );
  }
}

class _CreateDeckRow extends StatelessWidget {
  const _CreateDeckRow({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DashedBorder(
        color: colors.primaryBorder,
        radius: CoFitDimens.radiusLg,
        child: Container(
          padding: const EdgeInsets.all(CoFitDimens.spacingMd),
          decoration: BoxDecoration(
            color: colors.primaryMain.withValues(alpha: CoFitOpacities.faint),
            borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: CoFitDimens.spacingSm,
            children: [
              Container(
                width: CoFitDimens.sizeCheckBadge,
                height: CoFitDimens.sizeCheckBadge,
                decoration: BoxDecoration(
                  color: colors.primaryMain,
                  borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
                ),
                child: Icon(
                  Icons.add,
                  size: CoFitDimens.sizeCardIcon,
                  color: colors.primaryOn,
                ),
              ),
              Text(
                '新建牌组',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: CoFitFontWeights.heading,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 叠牌缩略:两张中性「牌背」+ 一张主色牌面;空组时牌面为虚线占位(#15a)。
class _DeckStack extends StatelessWidget {
  const _DeckStack({required this.accent, this.isEmpty = false});

  final Color accent;
  final bool isEmpty;

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

    final frontCard = isEmpty
        ? DashedBorder(
            color: colors.borderStrong,
            radius: CoFitDimens.radiusXs,
            strokeWidth: CoFitDimens.borderWidthHairline,
            child: const SizedBox(width: cardW, height: cardH),
          )
        : miniCard(accent, 0);

    return SizedBox(
      width: CoFitDimens.sizeDeckStackWidth,
      height: CoFitDimens.sizeDeckStackHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: slackY / 2,
            child:
                miniCard(colors.borderSubtle, CoFitDecor.deckStackTiltBackDeg),
          ),
          Positioned(
            left: slackX / 2,
            top: slackY / 4,
            child:
                miniCard(colors.borderStrong, CoFitDecor.deckStackTiltMidDeg),
          ),
          Positioned(left: slackX, top: 0, child: frontCard),
        ],
      ),
    );
  }
}

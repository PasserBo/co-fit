import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/dashed_border.dart';
import '../../domain/entity/action_source.dart';
import '../../domain/entity/action_template_card.dart';
import '../../domain/entity/action_type.dart';
import 'action_card.dart';
import 'action_type_style.dart';

/// 牌库 tab(#12b):创建卡片横幅 + 按类型分区的横滑卡片列。
/// 纯展示:数据与回调全部由外部注入。
class LibraryTabBody extends StatelessWidget {
  const LibraryTabBody({
    required this.cards,
    this.onCreateCard,
    this.onCardTap,
    this.onShareCard,
    this.onSeeAll,
    super.key,
  });

  final List<ActionTemplateCard> cards;
  final VoidCallback? onCreateCard;
  final ValueChanged<ActionTemplateCard>? onCardTap;
  final ValueChanged<ActionTemplateCard>? onShareCard;
  final ValueChanged<ActionType>? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final sections = [
      for (final type in ActionType.values)
        (type, cards.where((card) => card.type == type).toList()),
    ].where((section) => section.$2.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: CoFitDimens.spacingSm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CoFitDimens.spacingLg),
          child: _CreateCardBanner(onTap: onCreateCard),
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        for (final (type, sectionCards) in sections) ...[
          _TypeSection(
            type: type,
            cards: sectionCards,
            onCardTap: onCardTap,
            onShareCard: onShareCard,
            onSeeAll: onSeeAll,
          ),
          const SizedBox(height: CoFitDimens.spacingLg),
        ],
      ],
    );
  }
}

class _CreateCardBanner extends StatelessWidget {
  const _CreateCardBanner({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
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
            spacing: CoFitDimens.spacingMd,
            children: [
              Container(
                width: CoFitDimens.sizeBannerIcon,
                height: CoFitDimens.sizeBannerIcon,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('创建卡片', style: textTheme.titleSmall),
                    Text(
                      '按你的运动习惯自定义 · 可分享给好友',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.cards,
    this.onCardTap,
    this.onShareCard,
    this.onSeeAll,
  });

  final ActionType type;
  final List<ActionTemplateCard> cards;
  final ValueChanged<ActionTemplateCard>? onCardTap;
  final ValueChanged<ActionTemplateCard>? onShareCard;
  final ValueChanged<ActionType>? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CoFitDimens.spacingLg,
            0,
            CoFitDimens.spacingLg,
            CoFitDimens.spacingSm,
          ),
          child: Row(
            spacing: CoFitDimens.spacingSm,
            children: [
              Container(
                width: CoFitDimens.sizeSectionDot,
                height: CoFitDimens.sizeSectionDot,
                decoration: BoxDecoration(
                  color: type.mainOf(colors),
                  borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
                ),
              ),
              Text(type.sectionTitle, style: textTheme.titleSmall),
              Text(
                '${cards.length}',
                style:
                    textTheme.labelSmall?.copyWith(color: colors.textDisabled),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll == null ? null : () => onSeeAll!(type),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  '全部 ›',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colors.textTertiary),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: CoFitDimens.spacingLg),
          child: Row(
            spacing: CoFitDimens.spacingSm,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final card in cards)
                SizedBox(
                  width: CoFitDimens.sizeLibraryCardItem,
                  child: ActionCard(
                    card: card,
                    onTap:
                        onCardTap == null ? null : () => onCardTap!(card),
                    onShare: card.source == ActionSource.custom &&
                            onShareCard != null
                        ? () => onShareCard!(card)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

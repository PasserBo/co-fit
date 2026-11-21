import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../action/presentation/widget/action_type_style.dart';
import '../../provider/home_sheet_providers.dart';
import '../module/home_sheet_module.dart';
import '../widget/home_sheet_panel.dart';

/// 「今日推荐」模块:展示当前手牌里的一张卡;点它 → 面板收起,
/// 手牌进入选卡状态且这张卡在正中(规格「今日推荐直达选卡」)。
class RecommendationModuleView extends ConsumerWidget {
  const RecommendationModuleView({required this.host, super.key});

  final HomeSheetHost host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(recommendedCardProvider);
    if (card == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final minutes = (card.defaultDurationSec / Duration.secondsPerMinute)
        .ceil();

    return HomeSheetModuleFrame(
      key: const ValueKey('home_sheet_recommendation'),
      onTap: () {
        host
          ..focusFanOnCard(card.id)
          ..collapseSheet();
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '今日推荐',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  card.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  '${card.type.label} · $minutes 分钟',
                  style: textTheme.labelSmall?.copyWith(
                    color: card.type.mainOf(colors),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: CoFitDimens.spacingMd),
          // 卡片缩略:类型色小卡,提示「点了会拿到这张卡」
          Container(
            width: CoFitDimens.sizeDeckStackCardWidth,
            height: CoFitDimens.sizeDeckStackCardHeight,
            decoration: BoxDecoration(
              color: card.type.subtleOf(colors),
              borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
              border: Border.all(
                color: card.type.mainOf(colors),
                width: CoFitDimens.borderWidthHairline,
              ),
            ),
          ),
          const SizedBox(width: CoFitDimens.spacingSm),
          Icon(
            Icons.chevron_right,
            size: CoFitDimens.spacingXl,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }
}

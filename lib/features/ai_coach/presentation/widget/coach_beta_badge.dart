import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 「Beta」小徽章(入口与教练页标题共用)。
class CoachBetaBadge extends StatelessWidget {
  const CoachBetaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CoFitDimens.spacingXs),
      decoration: BoxDecoration(
        color: colors.primarySubtle,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
      ),
      child: Text(
        'Beta',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primaryMain,
          fontWeight: CoFitFontWeights.label,
        ),
      ),
    );
  }
}

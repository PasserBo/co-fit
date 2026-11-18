import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 演示房间的单条引导文案(纯展示):surface 底 + lime 淡描边胶囊卡。
/// 不拦截手势——由外层 `IgnorePointer` 保证,用户可直接操作下面的手牌。
class TourHintBubble extends StatelessWidget {
  const TourHintBubble({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingLg,
        vertical: CoFitDimens.spacingMd,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.primaryBorder,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

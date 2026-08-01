import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 牌库页顶部 segmented 切换(#12b:选中 = lime 实底胶囊)。
class LibrarySegmentedControl extends StatelessWidget {
  const LibrarySegmentedControl({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(CoFitDimens.spacingXs),
      decoration: ShapeDecoration(
        color: colors.bgSurface,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingXs,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: kThemeAnimationDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: CoFitDimens.spacingLg,
                  vertical: CoFitDimens.spacingSm,
                ),
                decoration: ShapeDecoration(
                  color: i == index ? colors.primaryMain : null,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  labels[i],
                  style: textTheme.labelLarge?.copyWith(
                    color: i == index ? colors.primaryOn : colors.textSecondary,
                    fontWeight: i == index
                        ? CoFitFontWeights.heading
                        : CoFitFontWeights.label,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

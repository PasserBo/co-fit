import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 选今日目标的底部面板(纯展示)。返回选中的值;滑掉返回 null。
Future<int?> showDailyTargetSheet(
  BuildContext context, {
  required List<int> choices,
  required int current,
  required String unit,
}) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (_) =>
        DailyTargetSheet(choices: choices, current: current, unit: unit),
  );
}

class DailyTargetSheet extends StatelessWidget {
  const DailyTargetSheet({
    required this.choices,
    required this.current,
    required this.unit,
    super.key,
  });

  final List<int> choices;
  final int current;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CoFitDimens.spacingXl,
          CoFitDimens.spacingSm,
          CoFitDimens.spacingXl,
          CoFitDimens.spacingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日目标',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingXs),
            Text(
              '每天沿用,随时可以再改',
              style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            Wrap(
              spacing: CoFitDimens.spacingSm,
              runSpacing: CoFitDimens.spacingSm,
              children: [
                for (final value in choices)
                  _TargetChoice(
                    key: ValueKey('daily_target_$value'),
                    label: '$value $unit',
                    selected: value == current,
                    onTap: () => Navigator.of(context).pop(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetChoice extends StatelessWidget {
  const _TargetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: CoFitDimens.sizeMinTapTarget,
            minWidth: CoFitDimens.sizeMinTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CoFitDimens.spacingLg,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primarySubtle : colors.bgApp,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
            border: Border.all(
              color: selected ? colors.primaryBorder : colors.borderSubtle,
              width: selected
                  ? CoFitDimens.borderWidthFocus
                  : CoFitDimens.borderWidthHairline,
            ),
          ),
          // 不用 Container.alignment:它会把选项撑满整行
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.primaryMain : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

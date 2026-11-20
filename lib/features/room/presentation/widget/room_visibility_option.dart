import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 建房页可见性单选卡:图标 + 名称 + 「谁能找到这个房间」说明。
/// 纯展示组件,选中态与回调由页面持有。
class RoomVisibilityOption extends StatelessWidget {
  const RoomVisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  /// null = 不可点(提交中)。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: CoFitMotion.dockExpand,
          constraints: const BoxConstraints(
            minHeight: CoFitDimens.sizeMinTapTarget,
          ),
          padding: const EdgeInsets.all(CoFitDimens.spacingMd),
          decoration: BoxDecoration(
            color: selected ? colors.primarySubtle : colors.bgSurface,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
            border: Border.all(
              color: selected ? colors.primaryBorder : colors.borderSubtle,
              width: CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Row(
            spacing: CoFitDimens.spacingMd,
            children: [
              Icon(
                icon,
                size: CoFitDimens.sizeCardIcon,
                color: selected ? colors.primaryMain : colors.textSecondary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CoFitDimens.spacingXs / 2,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: CoFitFontWeights.heading,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: CoFitDimens.sizeCardIcon,
                color: selected ? colors.primaryMain : colors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

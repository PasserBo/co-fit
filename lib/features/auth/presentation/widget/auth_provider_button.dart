import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 第三方登录按钮(纯展示)。
/// 默认 = surface 底描边款(Google);[apple] = HIG 黑白款
/// (gray-50 底 + gray-950 字,#19a 定稿,按 HIG 置于最上方)。
class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.apple = false,
    super.key,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool apple;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final foreground = apple ? colors.primaryOn : colors.textPrimary;

    return SizedBox(
      height: CoFitDimens.sizeMinTapTarget,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: apple ? colors.textPrimary : colors.bgSurface,
          foregroundColor: foreground,
          side: apple
              ? BorderSide.none
              : BorderSide(
                  color: colors.borderStrong,
                  width: CoFitDimens.borderWidthHairline,
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: CoFitDimens.spacingLg,
                height: CoFitDimens.spacingLg,
                child: CircularProgressIndicator(
                  strokeWidth: CoFitDimens.borderWidthFocus,
                  color: apple ? foreground : colors.textSecondary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: CoFitDimens.spacingSm),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: CoFitFontWeights.label,
                      color: foreground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

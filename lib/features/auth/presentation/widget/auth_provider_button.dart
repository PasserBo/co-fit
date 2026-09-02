import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 第三方登录按钮(纯展示)。Google 先用;E1-Apple 落地时同款复用,
/// Apple 按钮按 HIG 置于最上方。
class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return SizedBox(
      height: CoFitDimens.sizeMinTapTarget,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.bgSurface,
          foregroundColor: colors.textPrimary,
          side: BorderSide(
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
                  color: colors.textSecondary,
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
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

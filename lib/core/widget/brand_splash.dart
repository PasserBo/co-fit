import 'package:flutter/material.dart';

import '../../features/avatar/presentation/idle_avatar_figure.dart';
import '../theme/cofit_colors.dart';
import '../theme/cofit_dimens.dart';

/// 品牌 splash(登录态 / profile 加载期间),替代裸 CircularProgressIndicator。
/// 与 iOS 原生启动图同构(深底 + 小人),避免启动→Flutter 首帧的视觉跳变。
/// 纯展示。
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: CoFitDimens.spacingLg,
            children: [
              const IdleAvatarFigure(figureHeight: CoFitDimens.sizeFigureHero),
              Text(
                'CoFit',
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.primaryMain,
                  fontWeight: CoFitFontWeights.heading,
                ),
              ),
              SizedBox(
                width: CoFitDimens.spacingLg,
                height: CoFitDimens.spacingLg,
                child: CircularProgressIndicator(
                  strokeWidth: CoFitDimens.borderWidthFocus,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

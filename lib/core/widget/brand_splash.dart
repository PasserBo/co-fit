import 'package:flutter/material.dart';

import '../../features/avatar/presentation/idle_avatar_figure.dart';
import '../theme/cofit_colors.dart';
import '../theme/cofit_dimens.dart';

/// 品牌 splash(登录态 / profile / 启动数据加载期间),替代裸 CircularProgressIndicator。
/// 与 iOS 原生启动图同构(深底 + 小人),避免启动→Flutter 首帧的视觉跳变。
///
/// 入场:小人 + 字标在 [CoFitMotion.splashReveal] 内淡入上浮(接住原生启动图的静态画面);
/// [statusText] 为当前加载阶段的文案,切换时交叉淡出。纯展示。
class BrandSplash extends StatelessWidget {
  const BrandSplash({this.statusText, super.key});

  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: CoFitMotion.splashReveal,
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * CoFitDimens.spacingLg),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CoFitDimens.spacingLg,
              children: [
                const IdleAvatarFigure(
                  figureHeight: CoFitDimens.sizeFigureHero,
                ),
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
                // 阶段文案:固定占位高度,切换时不抖动布局
                SizedBox(
                  height: CoFitDimens.spacingXl,
                  child: AnimatedSwitcher(
                    duration: CoFitMotion.splashFade,
                    child: statusText == null
                        ? const SizedBox.shrink()
                        : Text(
                            statusText!,
                            key: ValueKey(statusText),
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

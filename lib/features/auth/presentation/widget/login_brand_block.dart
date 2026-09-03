import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';

/// 登录页品牌区(#19a):待机 bob 小人 + 两侧斜插装饰卡牌。
/// 小屏 375 下整体缩放由外层 ConstrainedBox 自然处理(舞台为固定 token 边长)。
class LoginBrandBlock extends StatelessWidget {
  const LoginBrandBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    // 小屏品牌区缩小(#19a 附注:小人缩 80%,按钮区不变)
    final compact = MediaQuery.sizeOf(context).width <=
        CoFitDimens.sizeAuthFormMaxWidth;
    final stage = compact
        ? CoFitDimens.sizeBrandStage * CoFitDecor.brandCompactScale
        : CoFitDimens.sizeBrandStage;

    Widget fanCard({required Color accent, required double tiltDeg}) {
      return Transform.rotate(
        angle: tiltDeg * math.pi / 180,
        child: Container(
          width: CoFitDimens.sizeLoginFanCardWidth,
          height: CoFitDimens.sizeLoginFanCardHeight,
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
            border: Border.all(
              color: accent.withValues(alpha: CoFitOpacities.silhouetteNear),
              width: CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: CoFitDimens.sizeCardTypeBar,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(CoFitDimens.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: stage,
      height: stage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: fanCard(
              accent: colors.typeStrength,
              tiltDeg: -CoFitDecor.loginFanTiltDeg,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: fanCard(
              accent: colors.typeFlexibility,
              tiltDeg: CoFitDecor.loginFanTiltDeg,
            ),
          ),
          IdleAvatarFigure(
            figureHeight: compact
                ? CoFitDimens.sizeFigureSelf
                : CoFitDimens.sizeFigureHero,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cofit_colors.dart';
import '../domain/entity/avatar_motion.dart';
import '../provider/avatar_renderer_provider.dart';
import 'renderer/avatar_renderer.dart';

/// 待机 bob 小人(空态/品牌区/邀请卡复用,#18b/#19a/#19b/#20)。
/// [figureHeight] 为形体高(token,如 sizeFigureHero);
/// [dimmed] = 灰色非活跃形态(#20c 非当前房间)。
class IdleAvatarFigure extends ConsumerWidget {
  const IdleAvatarFigure({
    required this.figureHeight,
    this.withHeadRing = true,
    this.dimmed = false,
    super.key,
  });

  final double figureHeight;
  final bool withHeadRing;
  final bool dimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final renderer = ref.watch(avatarRendererProvider);

    final figure = renderer.build(
      motion: AvatarMotion.idle(),
      appearance: AvatarAppearance(
        body: dimmed ? colors.statusIdle : colors.textPrimary,
        aura: colors.primaryMain,
        auraOpacity: dimmed ? 0 : CoFitOpacities.glow,
        headRing: withHeadRing && !dimmed
            ? colors.primaryMain.withValues(alpha: CoFitOpacities.strong)
            : null,
      ),
      // #14a 视框换算:形体(y18→y78)占视框 60/100
      height: figureHeight * (100 / 60),
    );

    if (!dimmed) {
      return figure;
    }
    return Opacity(opacity: CoFitOpacities.avatarInactive, child: figure);
  }
}

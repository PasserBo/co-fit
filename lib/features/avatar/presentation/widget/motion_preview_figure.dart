import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../action/domain/entity/action_type.dart';
import '../../../action/presentation/widget/action_type_style.dart';
import '../../domain/entity/avatar_motion.dart';
import '../../provider/avatar_renderer_provider.dart';
import '../renderer/avatar_renderer.dart';

/// 某个动作的 loop 预览小人(动作选择器 / 卡详情 / 自建卡表单复用):
/// 白身、类型色光圈、无描边;[motionId] 为 null 或未知时播该类型的原型。
class MotionPreviewFigure extends ConsumerWidget {
  const MotionPreviewFigure({
    required this.type,
    required this.figureHeight,
    this.motionId,
    this.phaseSeed = 0,
    super.key,
  });

  final ActionType type;
  final String? motionId;

  /// 形体高(token,如 sizeFigureSelf)。
  final double figureHeight;
  final double phaseSeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final renderer = ref.watch(avatarRendererProvider);
    return renderer.build(
      motion: AvatarMotion(
        state: AvatarMotionState.exercise,
        actionType: type,
        motionId: motionId,
      ),
      appearance: AvatarAppearance(
        body: colors.textPrimary,
        aura: type.mainOf(colors),
        auraOpacity: CoFitOpacities.auraActive,
        ink: colors.bgApp,
      ),
      height: avatarViewboxHeight(figureHeight),
      phaseSeed: phaseSeed,
    );
  }
}

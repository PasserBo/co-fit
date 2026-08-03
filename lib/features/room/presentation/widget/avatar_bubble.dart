import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../action/domain/entity/action_type.dart';
import '../../../action/presentation/widget/action_type_style.dart';
import '../../../avatar/domain/entity/avatar_motion.dart';
import '../../../avatar/presentation/motion/avatar_motion_sequencer.dart';
import '../../../avatar/presentation/renderer/avatar_renderer.dart';
import '../../domain/entity/user_activity_status_entity.dart';

/// 单个漂浮小人气泡(#6b + #14a 动作集):
/// 业务状态(idle/active/paused)经 [AvatarMotionSequencer] 编排为
/// 起手/loop/完成 的视觉序列,交给注入的 [AvatarRenderer] 播放。
///
/// 配色(#6b 定稿 + 2026-08-02 决议):
/// - 自己:gray-50 白身 + lime@90 常亮头环,「你」lime;
/// - 好友:整个小人 = 状态色 hue,无头环;
/// - 光圈:运动中 = 类型色 @28%,暂停 = amber @25%,待机 = 主体 hue @18%。
class AvatarBubble extends StatefulWidget {
  const AvatarBubble({
    required this.name,
    required this.state,
    required this.renderer,
    this.actionType,
    this.tempo = AvatarTempo.standard,
    this.chipText,
    this.isSelf = false,
    this.phaseSeed = 0,
    super.key,
  });

  final String name;
  final UserActivityState state;
  final AvatarRenderer renderer;

  /// 运动中的动作类型(决定 loop 原型与光圈类型色)。
  final ActionType? actionType;
  final AvatarTempo tempo;

  /// 动作说明(如「深蹲 10min」),null 时按状态显示占位文案。
  final String? chipText;
  final bool isSelf;

  /// 0–1 相位偏移(由 userId hash 派生),避免全房间齐步走。
  final double phaseSeed;

  @override
  State<AvatarBubble> createState() => _AvatarBubbleState();
}

class _AvatarBubbleState extends State<AvatarBubble> {
  late final AvatarMotionSequencer _sequencer = AvatarMotionSequencer()
    ..onLogicalState(
      widget.state,
      actionType: widget.actionType,
      tempo: widget.tempo,
    );

  @override
  void didUpdateWidget(AvatarBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = _sequencer.onLogicalState(
      widget.state,
      actionType: widget.actionType,
      tempo: widget.tempo,
    );
    if (changed) {
      setState(() {});
    }
  }

  void _handleOneShotComplete() {
    if (mounted && _sequencer.onOneShotComplete()) {
      setState(() {});
    }
  }

  Color _statusColor(CoFitColors colors) => switch (widget.state) {
        UserActivityState.active => colors.statusActive,
        UserActivityState.paused => colors.statusPaused,
        UserActivityState.idle => colors.statusIdle,
      };

  String get _fallbackChip => switch (widget.state) {
        UserActivityState.active => '运动中',
        UserActivityState.paused => '暂停中',
        UserActivityState.idle => '挂机',
      };

  AvatarAppearance _resolveAppearance(CoFitColors colors) {
    final statusColor = _statusColor(colors);
    final body = widget.isSelf ? colors.textPrimary : statusColor;
    final typeColor = widget.actionType?.mainOf(colors);
    final motion = _sequencer.current;

    final (Color aura, double auraOpacity) = switch (motion.state) {
      AvatarMotionState.exercise ||
      AvatarMotionState.windup ||
      AvatarMotionState.finish =>
        (typeColor ?? colors.primaryMain, CoFitOpacities.auraActive),
      AvatarMotionState.paused =>
        (colors.statusPaused, CoFitOpacities.auraPaused),
      AvatarMotionState.idle => (
          widget.isSelf ? colors.primaryMain : statusColor,
          CoFitOpacities.glow,
        ),
    };

    return AvatarAppearance(
      body: body,
      aura: aura,
      auraOpacity: auraOpacity,
      headRing: widget.isSelf
          ? colors.primaryMain.withValues(alpha: CoFitOpacities.strong)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(colors);

    final figureHeight = widget.isSelf
        ? CoFitDimens.sizeFigureSelf
        : CoFitDimens.sizeFigureFriend;
    // #14a 视框里形体(头顶 y18 → 脚底 y78)占 60/100,
    // token 定义的是形体高 → 换算出含光圈的视框高。
    final viewboxHeight = figureHeight * (100 / 60);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.renderer.build(
          motion: _sequencer.current,
          appearance: _resolveAppearance(colors),
          height: viewboxHeight,
          phaseSeed: widget.phaseSeed,
          onOneShotComplete: _handleOneShotComplete,
        ),
        const SizedBox(height: CoFitDimens.spacingXs),
        Text(
          widget.name,
          style: textTheme.labelSmall?.copyWith(
            color: widget.isSelf ? colors.primaryMain : colors.textSecondary,
            fontWeight: CoFitFontWeights.label,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          widget.chipText ?? _fallbackChip,
          style: textTheme.labelSmall?.copyWith(color: statusColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

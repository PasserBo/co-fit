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
/// - 离线([offline]):沿用 #20c 非活跃形态——灰身、无光圈,整体
///   `avatarInactive` 透明度,状态行「离线」。
class AvatarBubble extends StatefulWidget {
  const AvatarBubble({
    required this.name,
    required this.state,
    required this.renderer,
    this.actionType,
    this.motionId,
    this.tempo = AvatarTempo.standard,
    this.chipText,
    this.isSelf = false,
    this.offline = false,
    this.grounded = false,
    this.groundedReaction = true,
    this.labelOpacity = 1,
    this.phaseSeed = 0,
    super.key,
  });

  final String name;
  final UserActivityState state;
  final AvatarRenderer renderer;

  /// 运动中的动作类型(决定 loop 原型与光圈类型色)。
  final ActionType? actionType;

  /// 具体动作 clip id(P2);null/未知 → 类型原型。
  final String? motionId;
  final AvatarTempo tempo;

  /// 动作说明(如「深蹲 10min」),null 时按状态显示占位文案。
  final String? chipText;
  final bool isSelf;

  /// 房间成员但当前不在线(无 presence):变暗待机形态。
  final bool offline;

  /// 站在今日面板上沿(台上):待机改为站立,不上下浮动。
  final bool grounded;

  /// [grounded] 变化时是否播蓄力-腾空-落地的 ×1 反应(只在待机时生效)。
  final bool groundedReaction;

  /// 名字行与状态行的透明度(台上时由外部淡出)。
  final double labelOpacity;

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
      motionId: widget.motionId,
      tempo: widget.tempo,
    )
    ..onGrounded(widget.grounded, react: false);

  @override
  void didUpdateWidget(AvatarBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final logicalChanged = _sequencer.onLogicalState(
      widget.state,
      actionType: widget.actionType,
      motionId: widget.motionId,
      tempo: widget.tempo,
    );
    final groundedChanged = _sequencer.onGrounded(
      widget.grounded,
      react: widget.groundedReaction,
    );
    final changed = logicalChanged || groundedChanged;
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
    if (widget.offline) {
      return AvatarAppearance(
        body: colors.statusIdle,
        aura: colors.statusIdle,
        auraOpacity: 0,
        ink: colors.bgApp,
      );
    }
    final statusColor = _statusColor(colors);
    final body = widget.isSelf ? colors.textPrimary : statusColor;
    final typeColor = widget.actionType?.mainOf(colors);
    final motion = _sequencer.current;

    final (Color aura, double auraOpacity) = switch (motion.state) {
      AvatarMotionState.exercise ||
      AvatarMotionState.windup ||
      AvatarMotionState.finish => (
        typeColor ?? colors.primaryMain,
        CoFitOpacities.auraActive,
      ),
      AvatarMotionState.paused => (
        colors.statusPaused,
        CoFitOpacities.auraPaused,
      ),
      AvatarMotionState.idle ||
      AvatarMotionState.board ||
      AvatarMotionState.leave => (
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
      ink: colors.bgApp,
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
    // token 定义的是形体高 → 换算出含光圈的视框高(豆豆 82/100)。
    final viewboxHeight = avatarViewboxHeight(figureHeight);

    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.renderer.build(
          motion: _sequencer.current,
          appearance: _resolveAppearance(colors),
          height: viewboxHeight,
          phaseSeed: widget.phaseSeed,
          onOneShotComplete: _handleOneShotComplete,
        ),
        Opacity(
          opacity: widget.labelOpacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: CoFitDimens.spacingXs),
              Text(
                widget.name,
                style: textTheme.labelSmall?.copyWith(
                  color: widget.isSelf
                      ? colors.primaryMain
                      : colors.textSecondary,
                  fontWeight: CoFitFontWeights.label,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.offline ? '离线' : (widget.chipText ?? _fallbackChip),
                style: textTheme.labelSmall?.copyWith(
                  color: widget.offline ? colors.textTertiary : statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    if (!widget.offline) {
      return bubble;
    }
    return Opacity(opacity: CoFitOpacities.avatarInactive, child: bubble);
  }
}

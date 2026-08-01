import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/user_activity_status_entity.dart';

/// 单个漂浮小人气泡(#6b):状态光圈 + 占位小人 + 昵称 + 动作 chip。
/// 小人是占位形象(Rive 在范围外,见 STATUS 范围外清单),
/// 头/身/腿尺寸按 #6b mock 比例从 [figureHeight] 推导。
class AvatarBubble extends StatefulWidget {
  const AvatarBubble({
    required this.name,
    required this.state,
    this.chipText,
    this.isSelf = false,
    super.key,
  });

  final String name;
  final UserActivityState state;

  /// 动作说明(如「深蹲 10min」),null 时按状态显示占位文案。
  final String? chipText;
  final bool isSelf;

  @override
  State<AvatarBubble> createState() => _AvatarBubbleState();
}

class _AvatarBubbleState extends State<AvatarBubble>
    with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: CoFitMotion.bobPeriod,
  )..repeat(reverse: true);

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: CoFitMotion.breathePeriod,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    _breathe.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(colors);
    final active = widget.state == UserActivityState.active;

    final figureHeight = widget.isSelf
        ? CoFitDimens.sizeFigureSelf
        : CoFitDimens.sizeFigureFriend;
    final auraSize =
        widget.isSelf ? CoFitDimens.sizeAuraSelf : CoFitDimens.sizeAuraFriend;
    // 占位小人主体色:自己 = 高亮白 + lime 头圈,好友 = 状态色
    final figureColor = widget.isSelf ? colors.textPrimary : statusColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _breathe]),
      builder: (context, child) {
        final bobOffset = CoFitMotion.bobOffset *
            (Curves.easeInOut.transform(_bob.value) * 2 - 1);
        final breatheScale = active
            ? 1 +
                (CoFitMotion.breatheScale - 1) *
                    Curves.easeInOut.transform(_breathe.value)
            : 1.0;

        return Transform.translate(
          offset: Offset(0, bobOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: auraSize,
                height: figureHeight + CoFitDimens.spacingSm,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 0,
                      child: Transform.scale(
                        scale: breatheScale,
                        child: Container(
                          width: auraSize,
                          height: auraSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withValues(
                              alpha: active
                                  ? CoFitOpacities.glow
                                  : CoFitOpacities.faint,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _PlaceholderFigure(
                      height: figureHeight,
                      color: figureColor,
                      ringColor: widget.isSelf ? colors.primaryMain : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingXs),
              Text(
                widget.name,
                style: textTheme.labelSmall?.copyWith(
                  color:
                      widget.isSelf ? colors.primaryMain : colors.textSecondary,
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
          ),
        );
      },
    );
  }
}

/// 占位小人:头圆 + 圆角身体 + 双腿,比例由 #6b mock 推导(头≈0.30h,身≈0.44h,腿≈0.20h)。
class _PlaceholderFigure extends StatelessWidget {
  const _PlaceholderFigure({
    required this.height,
    required this.color,
    this.ringColor,
  });

  final double height;
  final Color color;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final head = height * 0.30;
    final bodyW = height * 0.34;
    final bodyH = height * 0.44;
    final legW = height * 0.09;
    final legH = height * 0.20;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: head,
          height: head,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: ringColor == null
                ? null
                : Border.all(
                    color: ringColor!,
                    width: CoFitDimens.borderWidthFocus,
                  ),
          ),
        ),
        SizedBox(height: height * 0.03),
        Container(
          width: bodyW,
          height: bodyH,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(bodyW / 2),
          ),
        ),
        SizedBox(height: height * 0.03),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: CoFitDimens.spacingXs,
          children: [
            for (var i = 0; i < 2; i++)
              Container(
                width: legW,
                height: legH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(legW / 2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

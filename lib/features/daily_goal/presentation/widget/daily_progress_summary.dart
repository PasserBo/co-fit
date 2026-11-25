import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/daily_progress.dart';
import 'progress_ring.dart';

/// 今日进度的一行摘要(纯展示):进度环 + 「当前 / 目标 单位」+ 一句提示。
/// 只认「当前 / 目标 / 单位」,不知道计量方式。[progress] 为 null = 占位。
class DailyProgressSummary extends StatefulWidget {
  const DailyProgressSummary({
    required this.progress,
    this.hint,
    this.animate = false,
    this.pulseTick = 0,
    this.trailing,
    super.key,
  });

  final DailyProgress? progress;

  /// 进度下方的一句提示;null = 按进度给默认提示。
  final String? hint;

  /// 进度环是否从旧值过渡到新值(false = 直接到位)。
  final bool animate;

  /// 每 +1 播一次达成强调(进度环放大再回弹)。
  final int pulseTick;

  final Widget? trailing;

  static String defaultHint(DailyProgress progress) => progress.reached
      ? '今日目标已达成'
      : '还差 ${progress.remaining} ${progress.unit}';

  @override
  State<DailyProgressSummary> createState() => _DailyProgressSummaryState();
}

class _DailyProgressSummaryState extends State<DailyProgressSummary>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: CoFitMotion.goalReachedPulse,
  );
  late final Animation<double> _pulseScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: CoFitDecor.goalReachedPulseScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: CoFitDecor.goalReachedPulseScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 1,
    ),
  ]).animate(_pulse);

  @override
  void didUpdateWidget(DailyProgressSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseTick != oldWidget.pulseTick) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final progress = widget.progress;
    final reached = progress?.reached ?? false;

    return Row(
      children: [
        ScaleTransition(
          scale: _pulseScale,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress?.fraction ?? 0),
            duration: widget.animate ? CoFitMotion.progressRoll : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, fraction, child) =>
                ProgressRing(fraction: fraction, child: child),
            child: reached
                ? Icon(
                    Icons.check,
                    size: CoFitDimens.spacingXl,
                    color: colors.primaryMain,
                  )
                : null,
          ),
        ),
        const SizedBox(width: CoFitDimens.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '今日进度',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: CoFitDimens.spacingXs),
              Text(
                progress == null
                    ? '—'
                    : '${progress.current} / ${progress.target} ${progress.unit}',
                key: const ValueKey('daily_progress_value'),
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (progress != null) ...[
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  widget.hint ?? DailyProgressSummary.defaultHint(progress),
                  key: const ValueKey('daily_progress_hint'),
                  style: textTheme.labelSmall?.copyWith(
                    color: reached ? colors.primaryMain : colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: CoFitDimens.spacingSm),
          widget.trailing!,
        ],
      ],
    );
  }
}

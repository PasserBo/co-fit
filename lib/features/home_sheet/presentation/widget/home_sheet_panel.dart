import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 今日面板的外壳(纯展示):把手 + 依次出现的模块。
/// 展开 / 收起的位移由外部按展开程度驱动;这里只负责外观与把手手势。
class HomeSheetPanel extends StatelessWidget {
  const HomeSheetPanel({
    required this.modules,
    required this.revealed,
    required this.bottomPadding,
    this.onHandleTap,
    this.onHandleDragStart,
    this.onHandleDragUpdate,
    this.onHandleDragEnd,
    this.reduceMotion = false,
    super.key,
  });

  final List<Widget> modules;

  /// 模块是否应当可见(展开程度超过阈值)。false → 一起快速淡出。
  final bool revealed;

  /// 底部安全区(home indicator)。
  final double bottomPadding;

  final VoidCallback? onHandleTap;
  final VoidCallback? onHandleDragStart;

  /// 参数:手指纵向位移(向下为正,逻辑像素)。
  final ValueChanged<double>? onHandleDragUpdate;

  /// 参数:松手时纵向速度(向下为正,px/s)。
  final ValueChanged<double>? onHandleDragEnd;

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: '今日面板把手',
            child: GestureDetector(
              key: const ValueKey('home_sheet_handle'),
              behavior: HitTestBehavior.opaque,
              onTap: onHandleTap,
              onVerticalDragStart: (_) => onHandleDragStart?.call(),
              onVerticalDragUpdate: (details) =>
                  onHandleDragUpdate?.call(details.delta.dy),
              onVerticalDragEnd: (details) =>
                  onHandleDragEnd?.call(details.velocity.pixelsPerSecond.dy),
              child: SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: CoFitDimens.sizeSheetGrabberWidth,
                    height: CoFitDimens.spacingXs,
                    decoration: BoxDecoration(
                      color: colors.borderStrong,
                      borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: CoFitDimens.spacingLg,
                right: CoFitDimens.spacingLg,
                bottom: bottomPadding + CoFitDimens.spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < modules.length; i++) ...[
                    if (i > 0) const SizedBox(height: CoFitDimens.spacingSm),
                    _ModuleReveal(
                      index: i,
                      revealed: revealed,
                      reduceMotion: reduceMotion,
                      child: modules[i],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 模块出现:淡入 + 上移,按顺序错开;消失时一起快速淡出。
class _ModuleReveal extends StatelessWidget {
  const _ModuleReveal({
    required this.index,
    required this.revealed,
    required this.reduceMotion,
    required this.child,
  });

  final int index;
  final bool revealed;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stagger = reduceMotion
        ? Duration.zero
        : CoFitMotion.sheetModuleStagger * index;
    final total = CoFitMotion.sheetModuleReveal + stagger;
    final start = stagger.inMicroseconds / total.inMicroseconds;
    final curve = revealed
        ? Interval(start, 1, curve: Curves.easeOut)
        : Curves.easeOut;
    final duration = revealed ? total : CoFitMotion.sheetModuleStagger;

    return AnimatedSlide(
      offset: revealed || reduceMotion
          ? Offset.zero
          : const Offset(0, _riseFraction),
      duration: duration,
      curve: curve,
      child: AnimatedOpacity(
        opacity: revealed ? 1 : 0,
        duration: duration,
        curve: curve,
        child: child,
      ),
    );
  }

  /// 上移量按模块自身高度的比例(AnimatedSlide 的单位),约等于一个 spacingSm。
  static const _riseFraction = 0.12;
}

/// 模块的统一外框(纯展示)。模块有内容时才画它。
class HomeSheetModuleFrame extends StatelessWidget {
  const HomeSheetModuleFrame({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final frame = Container(
      constraints: const BoxConstraints(
        minHeight: CoFitDimens.sizeMinTapTarget,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingMd,
        vertical: CoFitDimens.spacingMd,
      ),
      decoration: BoxDecoration(
        color: colors.bgApp,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: child,
    );
    if (onTap == null) {
      return frame;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: frame,
    );
  }
}

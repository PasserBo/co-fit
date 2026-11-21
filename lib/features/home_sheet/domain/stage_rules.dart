import '../../../core/theme/cofit_dimens.dart';

/// 今日面板「台子」的判定规则(纯函数,不依赖界面)。
///
/// 术语:`extent` = 面板展开程度,0 收起 → 1 展开;
/// `onStage` = 自己的小人是否(应当)站在面板上沿。
abstract final class StageRules {
  /// 拖动把手时小人是否在台上:低于 [CoFitDecor.stageDragLeave] 下台,
  /// 高于 [CoFitDecor.stageDragBoard] 回到台上;两个阈值之间保持原状(回差),
  /// 避免在临界点来回跳。
  static bool onStageWhileDragging({
    required bool onStage,
    required double extent,
  }) {
    if (onStage && extent < CoFitDecor.stageDragLeave) {
      return false;
    }
    if (!onStage && extent > CoFitDecor.stageDragBoard) {
      return true;
    }
    return onStage;
  }

  /// 松手后面板是否展开。快速甩动按甩动方向判定([velocityDy] 向下为正,
  /// px/s);否则「小人在不在台上 = 松手后的结果」。
  static bool expandedAfterRelease({
    required bool onStage,
    required double velocityDy,
  }) {
    if (velocityDy > CoFitDecor.stageFlingVelocity) {
      return false;
    }
    if (velocityDy < -CoFitDecor.stageFlingVelocity) {
      return true;
    }
    return onStage;
  }

  /// 面板高度:内容高度,不超过屏幕高度的 [CoFitDecor.sheetMaxHeightFraction]。
  static double sheetHeight({
    required double contentHeight,
    required double screenHeight,
  }) {
    final max = screenHeight * CoFitDecor.sheetMaxHeightFraction;
    return contentHeight < max ? contentHeight : max;
  }

  /// 场景(好友区域)下边距:收起时让出手牌,展开时让出面板,随 extent 过渡。
  /// 面板比手牌区矮时不收缩好友区域。
  static double sceneBottomInset({
    required double collapsedInset,
    required double sheetHeight,
    required double extent,
  }) {
    final expandedInset = sheetHeight > collapsedInset
        ? sheetHeight
        : collapsedInset;
    return collapsedInset + (expandedInset - collapsedInset) * extent;
  }
}

/// 小人一次起跳(上台 / 下台)在某一时刻的姿态。
typedef HopPose = ({double x, double y, double scale, double opacity});

/// 起跳轨迹(纯函数)。坐标是小人气泡左上角;y 向下为正。
abstract final class StageHop {
  /// [progress] 0–1 是整段(蓄力 + 腾空)的进度;[crouchFraction] 之前原地蓄力。
  /// 落点 [toX]/[toY] 每帧传入实时值(台面在动时落点跟着动)。
  /// 弧线:在直线插值之上叠加向上的 [arc]·sin(π·t)。
  static HopPose pose({
    required double progress,
    required double crouchFraction,
    required double fromX,
    required double fromY,
    required double fromScale,
    required double toX,
    required double toY,
    required double toScale,
    required double arc,
  }) {
    final t = airProgress(progress: progress, crouchFraction: crouchFraction);
    final eased = _easeInOut(t);
    return (
      x: fromX + (toX - fromX) * eased,
      y: fromY + (toY - fromY) * eased - arc * _sinPi(t),
      scale: fromScale + (toScale - fromScale) * eased,
      opacity: 1.0,
    );
  }

  /// 减弱动态效果:不位移,前半段在原地淡出,后半段在落点淡入。
  static HopPose reducedPose({
    required double progress,
    required double fromX,
    required double fromY,
    required double fromScale,
    required double toX,
    required double toY,
    required double toScale,
  }) {
    final atDestination = progress >= 0.5;
    return (
      x: atDestination ? toX : fromX,
      y: atDestination ? toY : fromY,
      scale: atDestination ? toScale : fromScale,
      opacity: (1 - 2 * progress).abs().clamp(0.0, 1.0),
    );
  }

  /// 腾空段的进度(0–1):蓄力阶段恒为 0。
  static double airProgress({
    required double progress,
    required double crouchFraction,
  }) {
    if (crouchFraction >= 1) {
      return progress >= 1 ? 1 : 0;
    }
    return ((progress - crouchFraction) / (1 - crouchFraction)).clamp(0.0, 1.0);
  }

  /// 弧高按起跳距离等比缩小(小屏上漂浮点离台面近):距离不足
  /// [CoFitDecor.stageHopArcFullDistance] 时线性缩小。
  static double arcFor({required double distance}) {
    final ratio = (distance.abs() / CoFitDecor.stageHopArcFullDistance).clamp(
      0.0,
      1.0,
    );
    return CoFitDecor.stageHopArc * ratio;
  }

  static double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t);

  /// 弧线形状:抛物线 4t(1−t),与 sin(π·t) 形状接近且端点精确为 0。
  static double _sinPi(double t) => 4 * t * (1 - t);
}

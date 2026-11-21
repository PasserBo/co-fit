import 'package:flutter/widgets.dart';

import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/stage_rules.dart';

/// 今日面板「台子」的状态与动画驱动(design.md §1–§6)。
///
/// - [extent]:面板展开程度 0–1,唯一事实源;手指拖动直接改它,
///   其余时候由可随时改目标的动画推动,所以任何时刻都能被打断。
/// - [onStage]:自己的小人是否(应当)在面板上沿。除拖动过程中外,
///   它与「面板是否展开」始终一致。
/// - 一次起跳([_hop])= 蓄力 + 腾空;落点由 [resolvePose] 每帧按实时台面计算。
class HomeStageController extends ChangeNotifier {
  HomeStageController({
    required TickerProvider vsync,
    bool expanded = true,
    this.onLand,
  }) : _onStage = expanded,
       _extent = AnimationController(vsync: vsync, value: expanded ? 1 : 0),
       _hop = AnimationController(vsync: vsync, value: 1),
       _dip = AnimationController(
         vsync: vsync,
         duration: CoFitMotion.stageLand,
         value: 1,
       ) {
    _extent.addListener(notifyListeners);
    _dip.addListener(notifyListeners);
    _hop
      ..addListener(_onHopTick)
      ..addStatusListener(_onHopStatus);
  }

  /// 小人落到台上的那一刻(触感反馈等)。
  final VoidCallback? onLand;

  final AnimationController _extent;
  final AnimationController _hop;
  final AnimationController _dip;

  bool _onStage;
  bool _available = true;
  bool _react = false;
  bool _lowerAtTakeoff = false;
  double _crouchFraction = 0;
  HopPose? _from;
  HopPose? _last;

  /// 系统「减弱动态效果」:不播弧线与蓄力,改为淡入淡出。
  bool reduceMotion = false;

  double get extent => _extent.value;
  bool get onStage => _onStage;

  /// 面板是否存在(至少一个模块可显示)。false 时点小人无反应。
  bool get available => _available;

  /// 最近一次上台 / 下台是否带蓄力反应(交给小人的编排器)。
  bool get reactToLastChange => _react;

  /// 小人是否在起跳途中(含刚发起、还没开始走帧的那一刻)。
  bool get isHopping => _hop.value < 1;

  bool _modulesRevealed = false;

  /// 面板里的模块是否应当可见:展开超过 [CoFitDecor.sheetModuleRevealAt] 时
  /// 出现(依次淡入);之后一直保持,直到面板完全收起才重置。
  /// 所以往下拖或收起的途中模块不会中途消失,而是跟着面板一起移出屏幕。
  bool get modulesRevealed {
    if (extent >= CoFitDecor.sheetModuleRevealAt) {
      _modulesRevealed = true;
    } else if (extent <= 0) {
      _modulesRevealed = false;
    }
    return _modulesRevealed;
  }

  /// 面板或小人的动画是否还在进行。进行中不接受新的点击与拖动
  /// (用户决议 2026-11-21:动画必须播完才能进行下一个操作)。
  bool get isBusy => isHopping || _extent.isAnimating;

  /// 落地时台面的瞬时下沉量(逻辑像素,向下为正)。
  double get dipOffset {
    final v = _dip.value;
    return CoFitDecor.stageLandDip * 4 * v * (1 - v);
  }

  /// 小人当前的缩放与透明度(不依赖布局,供 build 阶段使用)。
  double get scale => _poseWith(0, 0, 0, 0).scale;
  double get opacity => _poseWith(0, 0, 0, 0).opacity;

  /// 名字行透明度:漂浮时 1,台上 0,随缩放过渡。
  double get labelOpacity {
    const span = CoFitDecor.stageFigureScale - 1;
    return (1 - (scale - 1) / span).clamp(0.0, 1.0);
  }

  void setAvailable(bool value) {
    if (value == _available) {
      return;
    }
    _available = value;
    if (!value) {
      _hop.value = 1;
      _extent.value = 0;
      _onStage = false;
      _react = false;
      _from = null;
    }
    notifyListeners();
  }

  /// 点小人 / 点把手:在展开与收起之间切换。
  /// 动画进行中([isBusy])忽略。
  void toggle() {
    if (isBusy) {
      return;
    }
    _onStage ? collapse() : expand();
  }

  void expand({bool react = true}) {
    if (!_available) {
      return;
    }
    _setOnStage(true, react: react, moveExtent: true);
  }

  void collapse({bool react = true}) {
    _setOnStage(false, react: react, moveExtent: true);
  }

  bool _dragging = false;

  /// 动画进行中([isBusy])不能开始拖动。
  void dragStart() {
    _dragging = !isBusy && _available;
    _lowerAtTakeoff = false;
  }

  /// [deltaExtent]:本次手指移动折算的展开程度变化(向上为正)。
  void dragUpdate(double deltaExtent) {
    if (!_dragging) {
      return;
    }
    _extent.value = (_extent.value + deltaExtent).clamp(0.0, 1.0);
    _setOnStage(
      StageRules.onStageWhileDragging(onStage: _onStage, extent: extent),
      react: false,
      moveExtent: false,
    );
  }

  /// [velocityDy]:松手时的纵向速度,向下为正(px/s)。
  void dragEnd(double velocityDy) {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    final expanded = StageRules.expandedAfterRelease(
      onStage: _onStage,
      velocityDy: velocityDy,
    );
    _setOnStage(expanded, react: false, moveExtent: false);
    _animateExtent(expanded ? 1 : 0);
  }

  /// 布局阶段调用:给出漂浮点与台上位置(小人气泡左上角),返回当前应在的位置。
  HopPose resolvePose({
    required double floatX,
    required double floatY,
    required double stageX,
    required double stageY,
  }) {
    final pose = _poseWith(floatX, floatY, stageX, stageY);
    _last = pose;
    return pose;
  }

  HopPose _poseWith(
    double floatX,
    double floatY,
    double stageX,
    double stageY,
  ) {
    final toX = _onStage ? stageX : floatX;
    final toY = _onStage ? stageY : floatY;
    final toScale = _onStage ? CoFitDecor.stageFigureScale : 1.0;
    if (_hop.value >= 1) {
      return (x: toX, y: toY, scale: toScale, opacity: 1.0);
    }
    // 起点:起跳瞬间记录的位置;还没布局过时取上一个状态的归位点。
    final from =
        _from ??
        (
          x: _onStage ? floatX : stageX,
          y: _onStage ? floatY : stageY,
          scale: _onStage ? 1.0 : CoFitDecor.stageFigureScale,
          opacity: 1.0,
        );
    if (reduceMotion) {
      return StageHop.reducedPose(
        progress: _hop.value,
        fromX: from.x,
        fromY: from.y,
        fromScale: from.scale,
        toX: toX,
        toY: toY,
        toScale: toScale,
      );
    }
    return StageHop.pose(
      progress: _hop.value,
      crouchFraction: _crouchFraction,
      fromX: from.x,
      fromY: from.y,
      fromScale: from.scale,
      toX: toX,
      toY: toY,
      toScale: toScale,
      arc: StageHop.arcFor(distance: toY - from.y),
    );
  }

  void _setOnStage(
    bool value, {
    required bool react,
    required bool moveExtent,
  }) {
    if (value == _onStage) {
      if (moveExtent) {
        _animateExtent(value ? 1 : 0);
      }
      return;
    }
    // 起跳途中掉头、拖动触发、减弱动态效果:不蓄力。
    final withCrouch = react && !isHopping && !reduceMotion;
    _from = _last;
    _onStage = value;
    _react = withCrouch;

    final crouch = withCrouch ? CoFitMotion.stageCrouch : Duration.zero;
    final air = reduceMotion
        ? CoFitMotion.sheetModuleReveal
        : (value ? CoFitMotion.stageHopBoard : CoFitMotion.stageHopLeave);
    final total = crouch + air;
    _crouchFraction = crouch.inMicroseconds / total.inMicroseconds;

    // 上台:台子立即升起;下台:起跳那一刻台子才降(被蹬下去)。
    _lowerAtTakeoff = moveExtent && !value && withCrouch;
    if (moveExtent && !_lowerAtTakeoff) {
      _animateExtent(value ? 1 : 0);
    }
    _hop
      ..duration = total
      ..forward(from: 0);
    notifyListeners();
  }

  void _onHopTick() {
    if (_lowerAtTakeoff && _hop.value >= _crouchFraction) {
      _lowerAtTakeoff = false;
      _animateExtent(0);
    }
    notifyListeners();
  }

  void _onHopStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _from = null;
    if (_onStage) {
      if (!reduceMotion) {
        _dip.forward(from: 0);
      }
      onLand?.call();
    }
  }

  void _animateExtent(double target) {
    final distance = (target - _extent.value).abs();
    if (distance == 0) {
      // 已在目标位置:仍要停掉可能刚启动、朝另一个方向去的动画
      _extent.stop();
      return;
    }
    final base = reduceMotion
        ? CoFitMotion.sheetModuleReveal
        : CoFitMotion.stageRise;
    _extent.animateTo(
      target,
      duration: base * distance.clamp(CoFitDecor.fanSinkFadeBy, 1.0),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _extent.dispose();
    _hop.dispose();
    _dip.dispose();
    super.dispose();
  }
}

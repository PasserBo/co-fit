import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../action/domain/entity/action_type.dart';
import '../../domain/entity/avatar_motion.dart';
import 'avatar_renderer.dart';

/// Flutter 原生实现:CustomPaint 按 #14a 形体几何(80×100 视框)绘制。
///
/// 帧同步规范(README §关键帧同步,必读)在此落实:
/// 1. 每个小人只有一个 AnimationController(单一时钟);
/// 2. 所有部件从同一个 controller.value 派生,镜像肢体数学取反;
/// 3. 相位偏移用 (value + phaseSeed) % 1 计算,与启动时刻无关;
/// 4. 状态切换 controller 从 0 重启,×1 过渡动画掩盖跳变;
/// 5. hop 等 2 倍频子运动用同一 t 的频率映射,不另开时钟;
/// 6. 逐帧重绘走 CustomPainter.repaint(controller),不经过 setState/rebuild。
class VectorAvatarRenderer extends AvatarRenderer {
  const VectorAvatarRenderer();

  @override
  Widget build({
    required AvatarMotion motion,
    required AvatarAppearance appearance,
    required double height,
    double phaseSeed = 0,
    VoidCallback? onOneShotComplete,
    Key? key,
  }) {
    return VectorAvatarFigure(
      key: key,
      motion: motion,
      appearance: appearance,
      height: height,
      phaseSeed: phaseSeed,
      onOneShotComplete: onOneShotComplete,
    );
  }
}

class VectorAvatarFigure extends StatefulWidget {
  const VectorAvatarFigure({
    required this.motion,
    required this.appearance,
    required this.height,
    this.phaseSeed = 0,
    this.onOneShotComplete,
    super.key,
  });

  final AvatarMotion motion;
  final AvatarAppearance appearance;
  final double height;
  final double phaseSeed;
  final VoidCallback? onOneShotComplete;

  /// 形体视框 80×100(#14a),宽高比固定。
  static const aspectRatio = 0.8;

  @override
  State<VectorAvatarFigure> createState() => _VectorAvatarFigureState();
}

class _VectorAvatarFigureState extends State<VectorAvatarFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  bool get _isOneShot =>
      widget.motion.state == AvatarMotionState.windup ||
      widget.motion.state == AvatarMotionState.finish;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isOneShot) {
        widget.onOneShotComplete?.call();
      }
    });
    _restart();
  }

  @override
  void didUpdateWidget(VectorAvatarFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      _restart();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _tempoMultiplier(AvatarTempo tempo) => switch (tempo) {
        AvatarTempo.slow => CoFitDecor.tempoSlow,
        AvatarTempo.standard => 1.0,
        AvatarTempo.fast => CoFitDecor.tempoFast,
      };

  Duration _durationFor(AvatarMotion motion) {
    switch (motion.state) {
      case AvatarMotionState.idle:
        return CoFitMotion.bobPeriod;
      case AvatarMotionState.windup:
        return CoFitMotion.avatarWindup;
      case AvatarMotionState.finish:
        return CoFitMotion.avatarFinish;
      case AvatarMotionState.paused:
        return CoFitMotion.avatarLoopPaused;
      case AvatarMotionState.exercise:
        final base = switch (motion.actionType ?? ActionType.fallback) {
          ActionType.strength => CoFitMotion.avatarLoopStrength,
          ActionType.cardio => CoFitMotion.avatarLoopCardio,
          ActionType.core => CoFitMotion.avatarLoopCore,
          ActionType.flexibility => CoFitMotion.avatarLoopFlexibility,
        };
        return base * _tempoMultiplier(motion.tempo);
    }
  }

  void _restart() {
    _controller
      ..stop()
      ..duration = _durationFor(widget.motion)
      ..reset();
    if (_isOneShot) {
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(
        widget.height * VectorAvatarFigure.aspectRatio,
        widget.height,
      ),
      painter: _AvatarPainter(
        controller: _controller,
        motion: widget.motion,
        appearance: widget.appearance,
        // 只有 loop 需要相位偏移;×1 过渡必须从头播
        phaseSeed: _isOneShot ? 0 : widget.phaseSeed,
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required this.controller,
    required this.motion,
    required this.appearance,
    required this.phaseSeed,
  }) : super(repaint: controller);

  final AnimationController controller;
  final AvatarMotion motion;
  final AvatarAppearance appearance;
  final double phaseSeed;

  // ===== 波形工具(全部从同一个 t 派生) =====

  /// 0→1→0 三角波 + ease-in-out。
  static double _wave(double t) =>
      Curves.easeInOut.transform(1 - (2 * t - 1).abs());

  /// -1→1→-1 摆动波。
  static double _swing(double t) => 2 * _wave(t) - 1;

  /// 柔韧:顶点停留 20% 的波(0–40% 升,40–60% 停,60–100% 降)。
  static double _holdWave(double t) {
    if (t < 0.4) {
      return Curves.easeInOut.transform(t / 0.4);
    }
    if (t < 0.6) {
      return 1;
    }
    return Curves.easeInOut.transform((1 - t) / 0.4);
  }

  static double _deg(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final t = phaseSeed == 0
        ? controller.value
        : (controller.value + phaseSeed) % 1;
    // #14a 视框 80×100 → 画布缩放
    final s = size.height / 100;
    canvas.scale(s);

    switch (motion.state) {
      case AvatarMotionState.idle:
        _paintAura(canvas);
        _paintUpright(canvas, dy: -CoFitMotion.bobOffset * _wave(t));
      case AvatarMotionState.windup:
        _paintAura(canvas);
        _paintBurstRing(canvas, t);
        final scale = 1 + 0.16 * math.sin(math.pi * Curves.easeOut.transform(t));
        canvas.save();
        _scaleAround(canvas, scale, const Offset(40, 60));
        _paintUpright(canvas, arms: _ArmPose.side);
        canvas.restore();
      case AvatarMotionState.exercise:
        _paintExercise(canvas, t);
      case AvatarMotionState.paused:
        _paintAura(canvas);
        canvas.save();
        _rotateAround(canvas, _deg(5) * _swing(t), const Offset(40, 84));
        _paintUpright(canvas, opacity: CoFitOpacities.pausedFigure);
        canvas.restore();
      case AvatarMotionState.finish:
        _paintAura(canvas);
        _paintBurstRing(canvas, (t * 1.6).clamp(0.0, 1.0));
        _paintBurstRing(canvas, ((t - 0.12) * 1.6).clamp(0.0, 1.0));
        final dy = _finishJumpDy(t);
        canvas.save();
        canvas.translate(0, dy);
        final armProgress =
            Curves.easeOutBack.transform((t / 0.35).clamp(0.0, 1.0));
        _paintUpright(
          canvas,
          arms: _ArmPose.raised,
          armAngleDeg: 150 * armProgress,
        );
        canvas.restore();
    }
  }

  double _finishJumpDy(double t) {
    // 主跳 + 二段小跳(README:跳 −16px + 二段小跳)
    if (t < 0.55) {
      return -16 * math.sin(math.pi * t / 0.55);
    }
    if (t < 0.85) {
      return -6 * math.sin(math.pi * (t - 0.55) / 0.3);
    }
    return 0;
  }

  // ===== 运动 loop(按类型) =====

  void _paintExercise(Canvas canvas, double t) {
    switch (motion.actionType ?? ActionType.fallback) {
      case ActionType.strength:
        _paintStrength(canvas, t);
      case ActionType.cardio:
        _paintCardio(canvas, t);
      case ActionType.core:
        _paintCore(canvas, t);
      case ActionType.flexibility:
        _paintFlexibility(canvas, t);
    }
  }

  /// 力量·蹲起:上身下压 10px,腿 scaleY→.58(origin 脚底),臂 10°→75°。
  void _paintStrength(Canvas canvas, double t) {
    _paintAura(canvas);
    final w = _wave(t);
    final body = _bodyPaint();

    // 腿:压缩
    canvas.save();
    _scaleYAround(canvas, 1 - 0.42 * w, const Offset(40, 78));
    _drawLeg(canvas, body, x: 33);
    _drawLeg(canvas, body, x: 41.5);
    canvas.restore();

    // 上身整体下移
    canvas.save();
    canvas.translate(0, 10 * w);
    _drawTorso(canvas, body);
    final armAngle = _deg(10 + 65 * w);
    _drawArmRotated(canvas, body,
        x: 24.5, pivot: const Offset(27.25, 42), angle: -armAngle);
    _drawArmRotated(canvas, body,
        x: 50, pivot: const Offset(52.75, 42), angle: armAngle);
    _drawHead(canvas);
    canvas.restore();
  }

  /// 有氧·原地跑(侧视):前倾 8°,hop 2 倍频,腿 ±32° 交替,臂 ∓35° 反相。
  void _paintCardio(Canvas canvas, double t) {
    _paintAura(canvas);
    final swing = _swing(t);
    // 2 倍频 hop:同一个 t 的频率映射,不另开时钟
    final hop = -2.5 * _wave((t * 2) % 1);
    final near = _bodyPaint();
    final far = _bodyPaint(far: true);

    canvas.save();
    canvas.translate(0, hop);
    _rotateAround(canvas, _deg(8), const Offset(40, 84));

    // 远侧臂(反相于近侧 = 数学取反)
    _drawRunArm(canvas, far, angle: _deg(35) * swing);
    // 近侧腿 / 远侧腿(镜像取反)
    _drawRunLeg(canvas, near, angle: _deg(32) * swing);
    _drawRunLeg(canvas, far, angle: -_deg(32) * swing);
    _drawTorso(canvas, near);
    // 近侧臂
    _drawRunArm(canvas, near, angle: -_deg(35) * swing);
    _drawHead(canvas, cx: 42);
    canvas.restore();
  }

  /// 核心·支撑(侧视):静态姿势 + 1.6px 微颤;光圈加宽(rx24)。
  void _paintCore(Canvas canvas, double t) {
    _paintAura(canvas, rx: 24);
    final body = _bodyPaint();

    canvas.save();
    canvas.translate(0, 1.6 * _wave(t));
    // 躯干(水平,-6°)
    canvas.save();
    _rotateAround(canvas, _deg(-6), const Offset(39, 66));
    _drawRRect(canvas, body, const Rect.fromLTWH(24, 60, 30, 13), 6.5);
    canvas.restore();
    // 支撑臂(35°)
    canvas.save();
    _rotateAround(canvas, _deg(35), const Offset(22, 73));
    _drawRRect(canvas, body, const Rect.fromLTWH(19.25, 72, 5.5, 12), 2.75);
    canvas.restore();
    // 后腿
    _drawRRect(canvas, body, const Rect.fromLTWH(49, 73, 5.5, 11), 2.75);
    _drawHead(canvas, cx: 62, cy: 54);
    canvas.restore();
  }

  /// 柔韧·伸展:上身 0→−16°(顶点停 20%),单臂固定过头 −150°。
  void _paintFlexibility(Canvas canvas, double t) {
    _paintAura(canvas);
    final body = _bodyPaint();

    // 腿固定
    _drawLeg(canvas, body, x: 33);
    _drawLeg(canvas, body, x: 41.5);

    canvas.save();
    _rotateAround(canvas, _deg(-16) * _holdWave(t), const Offset(40, 64));
    _drawTorso(canvas, body);
    // 左臂垂放
    _drawRRect(canvas, body, const Rect.fromLTWH(24.5, 41, 5.5, 12), 2.75);
    // 右臂固定过头
    _drawArmRotated(canvas, body,
        x: 50, pivot: const Offset(52.75, 42), angle: _deg(-150));
    _drawHead(canvas);
    canvas.restore();
  }

  // ===== 直立姿势(idle/windup/paused/finish 共用) =====

  void _paintUpright(
    Canvas canvas, {
    double dy = 0,
    _ArmPose arms = _ArmPose.none,
    double armAngleDeg = 0,
    double opacity = 1,
  }) {
    final body = _bodyPaint(opacity: opacity);
    canvas.save();
    canvas.translate(0, dy);
    _drawTorso(canvas, body);
    if (arms == _ArmPose.side) {
      _drawRRect(canvas, body, const Rect.fromLTWH(24.5, 41, 5.5, 12), 2.75);
      _drawRRect(canvas, body, const Rect.fromLTWH(50, 41, 5.5, 12), 2.75);
    } else if (arms == _ArmPose.raised) {
      final angle = _deg(armAngleDeg);
      _drawArmRotated(canvas, body,
          x: 24.5, pivot: const Offset(27.25, 42), angle: angle);
      _drawArmRotated(canvas, body,
          x: 50, pivot: const Offset(52.75, 42), angle: -angle);
    }
    _drawLeg(canvas, body, x: 33);
    _drawLeg(canvas, body, x: 41.5);
    _drawHead(canvas, opacity: opacity);
    canvas.restore();
  }

  // ===== 部件绘制 =====

  Paint _bodyPaint({bool far = false, double opacity = 1}) {
    var color = appearance.body;
    if (far) {
      color = color.withValues(alpha: CoFitOpacities.farLimb * opacity);
    } else if (opacity < 1) {
      color = color.withValues(alpha: opacity);
    }
    return Paint()..color = color;
  }

  void _paintAura(Canvas canvas, {double rx = 17}) {
    final paint = Paint()
      ..color = appearance.aura.withValues(alpha: appearance.auraOpacity);
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(40, 90), width: rx * 2, height: 9),
      paint,
    );
  }

  void _paintBurstRing(Canvas canvas, double t) {
    if (t <= 0 || t >= 1) {
      return;
    }
    final scale = 0.5 + 1.5 * Curves.easeOut.transform(t);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = appearance.aura.withValues(alpha: (1 - t));
    canvas.save();
    _scaleAround(canvas, scale, const Offset(40, 88));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(40, 88), width: 32, height: 10),
      paint,
    );
    canvas.restore();
  }

  void _drawRRect(Canvas canvas, Paint paint, Rect rect, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  void _drawTorso(Canvas canvas, Paint paint) {
    _drawRRect(canvas, paint, const Rect.fromLTWH(32.5, 38, 15, 24), 7.5);
  }

  void _drawLeg(Canvas canvas, Paint paint, {required double x}) {
    _drawRRect(canvas, paint, Rect.fromLTWH(x, 66, 5.5, 12), 2.75);
  }

  void _drawArmRotated(
    Canvas canvas,
    Paint paint, {
    required double x,
    required Offset pivot,
    required double angle,
  }) {
    canvas.save();
    _rotateAround(canvas, angle, pivot);
    _drawRRect(canvas, paint, Rect.fromLTWH(x, 41, 5.5, 12), 2.75);
    canvas.restore();
  }

  /// 侧视跑步的长臂(origin 肩 40,44)。
  void _drawRunArm(Canvas canvas, Paint paint, {required double angle}) {
    canvas.save();
    _rotateAround(canvas, angle, const Offset(40, 44));
    _drawRRect(canvas, paint, const Rect.fromLTWH(37.25, 46, 5.5, 18), 2.75);
    canvas.restore();
  }

  /// 侧视跑步腿(origin 髋 40,67)。
  void _drawRunLeg(Canvas canvas, Paint paint, {required double angle}) {
    canvas.save();
    _rotateAround(canvas, angle, const Offset(40, 67));
    _drawRRect(canvas, paint, const Rect.fromLTWH(37.25, 66, 5.5, 12), 2.75);
    canvas.restore();
  }

  void _drawHead(
    Canvas canvas, {
    double cx = 40,
    double cy = 26,
    double opacity = 1,
  }) {
    final fill = _bodyPaint(opacity: opacity);
    canvas.drawCircle(Offset(cx, cy), 8, fill);
    final ring = appearance.headRing;
    if (ring != null) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = opacity < 1 ? ring.withValues(alpha: opacity) : ring;
      canvas.drawCircle(Offset(cx, cy), 8, ringPaint);
    }
  }

  // ===== 变换工具 =====

  void _rotateAround(Canvas canvas, double angle, Offset pivot) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  void _scaleAround(Canvas canvas, double scale, Offset pivot) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(scale);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  void _scaleYAround(Canvas canvas, double scaleY, Offset pivot) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(1, scaleY);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) =>
      oldDelegate.motion != motion ||
      oldDelegate.appearance != appearance ||
      oldDelegate.phaseSeed != phaseSeed;
}

enum _ArmPose { none, side, raised }

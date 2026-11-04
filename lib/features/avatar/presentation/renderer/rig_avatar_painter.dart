import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import 'avatar_renderer.dart';
import 'rig/bone.dart';
import 'rig/motion_clip.dart';
import 'rig/pose_sampler.dart';
import 'rig/rig.dart';

/// 把 clip 在 t 时刻的 Pose 画成豆豆(docs/avatar_bean_spec.md)。
///
/// 帧同步规范(README)在此落实:
/// 1. 每个小人只有一个时钟([animation]);所有骨骼由 [PoseSampler] 从同一个 t 派生;
/// 2. 镜像肢体在 clip 的 mirrors 里数学取反;
/// 3. 相位偏移 (value + phaseSeed) % 1,与启动时刻无关;
/// 4. 逐帧重绘走 CustomPainter.repaint,不经过 setState。
/// [fixedT] 用于工作台/golden 定帧,给了就不读时钟。
class RigAvatarPainter extends CustomPainter {
  RigAvatarPainter({
    required this.clip,
    required this.appearance,
    this.phaseSeed = 0,
    Animation<double>? animation,
    double? fixedT,
  }) : _animation = animation,
       _fixedT = fixedT,
       assert(animation != null || fixedT != null),
       super(repaint: animation);

  final MotionClip clip;
  final AvatarAppearance appearance;
  final double phaseSeed;
  final Animation<double>? _animation;
  final double? _fixedT;

  double get _t {
    final raw = _fixedT ?? _animation!.value;
    return phaseSeed == 0 ? raw : (raw + phaseSeed) % 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = _t;
    final rig = Rig.of(clip.facing);
    final pose = PoseSampler.sample(clip, rig, t);
    canvas.scale(size.height / Rig.viewHeight);

    _paintAura(canvas, rig, clip.auraRx);
    for (final burst in clip.bursts) {
      final progress = burst.progressAt(t);
      if (progress != null) {
        _paintBurstRing(canvas, progress);
      }
    }

    for (final bone in rig.drawOrder) {
      final def = rig.bones[bone]!;
      canvas.save();
      canvas.transform(pose.world[bone]!.storage);
      switch (bone) {
        case Bone.spine:
          _paintEgg(canvas);
        case Bone.head:
          _paintFace(canvas, rig);
        default:
          final far = rig.facing == Facing.side && bone.isRightSide;
          _paintCapsules(canvas, def.capsules, far: far);
      }
      canvas.restore();
    }
  }

  // ===== 部件 =====

  Paint _bodyPaint({bool far = false}) {
    var alpha = clip.opacity;
    if (far) {
      alpha *= CoFitOpacities.farLimb;
    }
    return Paint()
      ..color = alpha < 1
          ? appearance.body.withValues(alpha: alpha)
          : appearance.body;
  }

  Paint? _gapPaint() {
    final ink = appearance.ink;
    if (ink == null) {
      return null;
    }
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Rig.limbGapStroke
      ..color = ink;
  }

  void _paintCapsules(Canvas canvas, List<Rect> capsules, {required bool far}) {
    final body = _bodyPaint(far: far);
    final gap = _gapPaint();
    for (final rect in capsules) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.shortestSide / 2),
      );
      if (gap != null) {
        canvas.drawRRect(rrect, gap);
      }
      canvas.drawRRect(rrect, body);
    }
  }

  void _paintEgg(Canvas canvas) {
    canvas.drawPath(Rig.eggPath, _bodyPaint());
    final ring = appearance.headRing;
    if (ring != null) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Rig.outlineStroke
        ..color = clip.opacity < 1
            ? ring.withValues(alpha: clip.opacity)
            : ring;
      canvas.drawPath(Rig.eggPath, ringPaint);
    }
  }

  void _paintFace(Canvas canvas, Rig rig) {
    final ink = appearance.ink;
    if (ink == null) {
      return;
    }
    final paint = Paint()
      ..color = clip.opacity < 1 ? ink.withValues(alpha: clip.opacity) : ink;
    for (final eye in rig.eyes) {
      canvas.drawCircle(eye, Rig.eyeRadius, paint);
    }
  }

  // ===== 效果(不随骨骼) =====

  void _paintAura(Canvas canvas, Rig rig, double rx) {
    if (rx <= 0) {
      return;
    }
    final paint = Paint()
      ..color = appearance.aura.withValues(alpha: appearance.auraOpacity);
    final center = rig.sockets[Socket.ground]!;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: 9),
      paint,
    );
  }

  void _paintBurstRing(Canvas canvas, double progress) {
    const center = Offset(40, 88);
    final scale = 0.5 + 1.5 * Curves.easeOut.transform(progress);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = appearance.aura.withValues(alpha: 1 - progress);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 32, height: 10),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(RigAvatarPainter oldDelegate) =>
      oldDelegate.clip != clip ||
      oldDelegate.appearance != appearance ||
      oldDelegate.phaseSeed != phaseSeed ||
      oldDelegate._fixedT != _fixedT ||
      oldDelegate._animation != _animation;
}

/// 工作台/golden 用:定帧画一个 clip。
class StaticAvatarFrame extends StatelessWidget {
  const StaticAvatarFrame({
    required this.clip,
    required this.appearance,
    required this.height,
    required this.t,
    this.phaseSeed = 0,
    super.key,
  });

  final MotionClip clip;
  final AvatarAppearance appearance;
  final double height;
  final double t;
  final double phaseSeed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * (Rig.viewWidth / Rig.viewHeight), height),
      painter: RigAvatarPainter(
        clip: clip,
        appearance: appearance,
        phaseSeed: phaseSeed,
        fixedT: t,
      ),
    );
  }
}

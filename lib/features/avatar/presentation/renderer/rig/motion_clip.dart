import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'bone.dart';
import 'bone_transform.dart';
import 'track.dart';

/// 与骨骼无关的程序绘制效果。
@immutable
sealed class ClipEffect {
  const ClipEffect();

  /// 地面光圈半宽(站姿 17,卧姿 26)。
  const factory ClipEffect.aura({double rx}) = AuraEffect;

  /// burst 环:从 [start] 起以 [speed] 倍速播 0.5→2 放大淡出。
  const factory ClipEffect.burst({double start, double speed}) = BurstEffect;
}

class AuraEffect extends ClipEffect {
  const AuraEffect({this.rx = 17});

  final double rx;
}

class BurstEffect extends ClipEffect {
  const BurstEffect({this.start = 0, this.speed = 1});

  final double start;
  final double speed;

  /// 该效果在 t 时刻的进度(0–1),不在播放区间返回 null。
  double? progressAt(double t) {
    final p = (t - start) * speed;
    if (p <= 0 || p >= 1) {
      return null;
    }
    return p;
  }
}

/// 整体舞台变换(卧姿用):绕 [pivot] 旋转 [rotDeg] 再平移,作用在 root 之外。
@immutable
class StageTransform {
  const StageTransform({
    required this.pivot,
    this.rotDeg = 0,
    this.translate = Offset.zero,
  });

  final Offset pivot;
  final double rotDeg;
  final Offset translate;
}

/// 一个动作 = 视角 + 周期 + 每根骨骼的轨道 + 镜像规则 + 效果(spec §5)。
/// 纯数据,不依赖 Flutter 渲染;周期是内容不是 token(实施计划 1.5)。
@immutable
class MotionClip {
  const MotionClip({
    required this.id,
    required this.facing,
    required this.period,
    this.loop = true,
    this.basePose = const {},
    this.tracks = const {},
    this.mirrors = const [],
    this.effects = const [ClipEffect.aura()],
    this.stage,
    this.opacity = 1,
  });

  final String id;
  final Facing facing;
  final Duration period;

  /// false = ×1 过渡(windup / finish),播完回调编排器。
  final bool loop;

  /// 静态姿势(先摆好再叠轨道)。
  final Map<Bone, BoneTransform> basePose;
  final Map<Bone, Track> tracks;
  final List<Mirror> mirrors;
  final List<ClipEffect> effects;
  final StageTransform? stage;

  /// 整体透明度(暂停 .75)。
  final double opacity;

  double get auraRx {
    for (final effect in effects) {
      if (effect is AuraEffect) {
        return effect.rx;
      }
    }
    return 0;
  }

  Iterable<BurstEffect> get bursts => effects.whereType<BurstEffect>();
}

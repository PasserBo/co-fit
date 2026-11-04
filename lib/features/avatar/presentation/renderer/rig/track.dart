import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'bone.dart';
import 'bone_transform.dart';

/// 关键帧:在 t(0–1)处的值,以及到下一帧的缓动。
@immutable
class Keyframe {
  const Keyframe(this.t, this.value, {this.curve = Curves.easeInOut});

  final double t;
  final BoneTransform value;
  final Curve curve;
}

/// 一根骨骼的轨道。首选关键帧;`sampled` 是逃生口(sin / easeOutBack 等
/// 非分段缓动),用于精确复现 #14a 的起手缩放与完成跳跃。
@immutable
sealed class Track {
  const Track();

  const factory Track.keys(List<Keyframe> keys) = KeyTrack;

  const factory Track.sampled(BoneTransform Function(double t) fn) =
      SampledTrack;

  /// 常量轨道(整段保持同一姿势)。
  const factory Track.constant(BoneTransform value) = ConstantTrack;

  /// a → b → a 的角度摆动(0→1→0 三角波 + ease-in-out,即 #14a 的 `_wave`)。
  const factory Track.swing(double fromDeg, double toDeg) = SwingTrack;

  /// a → b(40%)停到 60% → a:顶点停留 20%(柔韧类,#14a 的 `_holdWave`)。
  const factory Track.hold(double fromDeg, double toDeg) = HoldTrack;

  BoneTransform sample(double t);
}

class KeyTrack extends Track {
  /// 至少 2 帧;loop clip 首尾帧值应相同。
  const KeyTrack(this.keys);

  final List<Keyframe> keys;

  @override
  BoneTransform sample(double t) {
    if (t <= keys.first.t) {
      return keys.first.value;
    }
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i];
      final b = keys[i + 1];
      if (t <= b.t) {
        final span = b.t - a.t;
        if (span <= 0) {
          return b.value;
        }
        final local = a.curve.transform(((t - a.t) / span).clamp(0.0, 1.0));
        return a.value.lerpTo(b.value, local);
      }
    }
    return keys.last.value;
  }
}

class SampledTrack extends Track {
  const SampledTrack(this.fn);

  final BoneTransform Function(double t) fn;

  @override
  BoneTransform sample(double t) => fn(t);
}

class SwingTrack extends Track {
  const SwingTrack(this.fromDeg, this.toDeg);

  final double fromDeg;
  final double toDeg;

  /// 0→1→0 三角波 + ease-in-out。
  static double wave(double t) =>
      Curves.easeInOut.transform(1 - (2 * t - 1).abs());

  @override
  BoneTransform sample(double t) =>
      BoneTransform(rotDeg: fromDeg + (toDeg - fromDeg) * wave(t));
}

class HoldTrack extends Track {
  const HoldTrack(this.fromDeg, this.toDeg);

  final double fromDeg;
  final double toDeg;

  static double wave(double t) {
    if (t < 0.4) {
      return Curves.easeInOut.transform(t / 0.4);
    }
    if (t < 0.6) {
      return 1;
    }
    return Curves.easeInOut.transform((1 - t) / 0.4);
  }

  @override
  BoneTransform sample(double t) =>
      BoneTransform(rotDeg: fromDeg + (toDeg - fromDeg) * wave(t));
}

class ConstantTrack extends Track {
  const ConstantTrack(this.value);

  final BoneTransform value;

  @override
  BoneTransform sample(double t) => value;
}

/// 镜像规则(README 帧同步规范 2):target 的局部变换 = from 的取反,
/// 相位由公式保证,与启动时刻无关。
@immutable
class Mirror {
  const Mirror(
    this.target, {
    required this.from,
    this.negateRot = true,
    this.negateDx = false,
  });

  final Bone target;
  final Bone from;
  final bool negateRot;
  final bool negateDx;
}

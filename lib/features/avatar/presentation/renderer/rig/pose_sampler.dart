import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'bone.dart';
import 'bone_transform.dart';
import 'motion_clip.dart';
import 'rig.dart';

/// 采样结果:每根骨骼的世界矩阵(视框坐标)+ 局部变换(测试/工作台用)。
@immutable
class Pose {
  const Pose({required this.world, required this.local});

  final Map<Bone, Matrix4> world;
  final Map<Bone, BoneTransform> local;
}

/// 纯函数:clip × rig × t → Pose。README 帧同步规范在此落实:
/// 所有骨骼从同一个 t 派生;镜像用数学取反;与启动时刻无关。
abstract final class PoseSampler {
  static Pose sample(MotionClip clip, Rig rig, double t) {
    // 1. 局部变换 = basePose ∘ track(t)
    final local = <Bone, BoneTransform>{};
    for (final bone in Bone.values) {
      final base = clip.basePose[bone] ?? BoneTransform.identity;
      final track = clip.tracks[bone];
      local[bone] = track == null ? base : base.compose(track.sample(t));
    }
    // 2. 镜像派生
    for (final mirror in clip.mirrors) {
      local[mirror.target] = local[mirror.from]!.mirrored(
        negateRot: mirror.negateRot,
        negateDx: mirror.negateDx,
      );
    }
    // 3. 沿父链合成世界矩阵(父先算:Bone 枚举顺序即父在前)
    final world = <Bone, Matrix4>{};
    final stage = _stageMatrix(clip.stage);
    for (final bone in Bone.values) {
      final def = rig.bones[bone]!;
      final parentWorld = def.parent == null ? stage : world[def.parent!]!;
      world[bone] = parentWorld.multiplied(_localMatrix(def, local[bone]!));
    }
    return Pose(world: world, local: local);
  }

  static Matrix4 _stageMatrix(StageTransform? stage) {
    if (stage == null) {
      return Matrix4.identity();
    }
    final p = stage.pivot;
    return Matrix4.translationValues(
          stage.translate.dx + p.dx,
          stage.translate.dy + p.dy,
          0,
        )
        .multiplied(Matrix4.rotationZ(_rad(stage.rotDeg)))
        .multiplied(Matrix4.translationValues(-p.dx, -p.dy, 0));
  }

  /// T(pivot) · T(dx,dy) · R(rot) · S(sx,sy) · T(−pivot)
  static Matrix4 _localMatrix(BoneDef def, BoneTransform tf) {
    if (tf.isIdentity) {
      return Matrix4.identity();
    }
    final p = def.pivot;
    return Matrix4.translationValues(p.dx + tf.dx, p.dy + tf.dy, 0)
        .multiplied(Matrix4.rotationZ(_rad(tf.rotDeg)))
        .multiplied(Matrix4.diagonal3Values(tf.scaleX, tf.scaleY, 1))
        .multiplied(Matrix4.translationValues(-p.dx, -p.dy, 0));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

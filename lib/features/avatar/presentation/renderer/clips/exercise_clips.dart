import 'dart:ui';

import '../rig/bone.dart';
import '../rig/bone_transform.dart';
import '../rig/motion_clip.dart';
import '../rig/track.dart';

/// P2 第一批具体动作(docs/avatar_implementation_plan.md §2.4),每类型 2 个;
/// 4 个类型原型在 core_states.dart。角度顺时针为正,四肢 rest 向下。
abstract final class ExerciseClips {
  static const _zero = BoneTransform.identity;

  /// 仰卧舞台:绕 (40,50) 转 −90(头朝左、面朝上),平移到地面。
  static const _supine = StageTransform(
    pivot: Offset(40, 50),
    rotDeg: -90,
    translate: Offset(2, 18),
  );

  /// 俯撑舞台(与平板同):头朝右、面朝下。
  static const _prone = StageTransform(
    pivot: Offset(40, 50),
    rotDeg: 90,
    translate: Offset(-3, 20),
  );

  // ===== 力量 =====

  /// 弓步蹲(侧面):前腿(近)屈膝向前,后腿(远)膝盖下沉,骨盆下沉 8。
  static const lunge = MotionClip(
    id: 'lunge',
    facing: Facing.side,
    period: Duration(milliseconds: 1400),
    basePose: {
      Bone.uarmL: BoneTransform(rotDeg: -20),
      Bone.farmL: BoneTransform(rotDeg: -60),
      Bone.uarmR: BoneTransform(rotDeg: -20),
      Bone.farmR: BoneTransform(rotDeg: -60),
    },
    tracks: {
      Bone.pelvis: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: 8)),
        Keyframe(1, _zero),
      ]),
      Bone.thighL: Track.swing(-30, -50),
      Bone.shinL: Track.swing(30, 60),
      Bone.thighR: Track.swing(25, 35),
      Bone.shinR: Track.swing(20, 60),
      Bone.spine: Track.swing(0, 6),
    },
  );

  /// 俯卧撑(侧面):俯撑舞台,肘弯 46° / 前臂 92°,身体下沉 6。
  static const pushup = MotionClip(
    id: 'pushup',
    facing: Facing.side,
    period: Duration(milliseconds: 1200),
    stage: _prone,
    basePose: {
      Bone.uarmL: BoneTransform(rotDeg: -90),
      Bone.uarmR: BoneTransform(rotDeg: -90),
      Bone.head: BoneTransform(rotDeg: -12),
    },
    tracks: {
      Bone.root: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: 6)),
        Keyframe(1, _zero),
      ]),
      Bone.uarmL: Track.swing(0, -46),
      Bone.uarmR: Track.swing(0, -46),
      Bone.farmL: Track.swing(0, 92),
      Bone.farmR: Track.swing(0, 92),
    },
    effects: [ClipEffect.aura(rx: 26)],
  );

  // ===== 有氧 =====

  /// 开合跳(正面):hop −4,双臂 12→160,双腿外展 26、小腿反向保持脚平。
  static const jumpingJack = MotionClip(
    id: 'jumping_jack',
    facing: Facing.front,
    period: Duration(milliseconds: 700),
    tracks: {
      Bone.root: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: -4)),
        Keyframe(1, _zero),
      ]),
      Bone.uarmL: Track.swing(12, 160),
      Bone.farmL: Track.swing(0, -12),
      Bone.thighL: Track.swing(0, 26),
      Bone.shinL: Track.swing(0, -26),
    },
    mirrors: [
      Mirror(Bone.uarmR, from: Bone.uarmL),
      Mirror(Bone.farmR, from: Bone.farmL),
      Mirror(Bone.thighR, from: Bone.thighL),
      Mirror(Bone.shinR, from: Bone.shinL),
    ],
  );

  /// 高抬腿(侧面):大腿交替抬到水平(−90),小腿垂下,hop 2 倍频。
  static const highKnees = MotionClip(
    id: 'high_knees',
    facing: Facing.side,
    period: Duration(milliseconds: 500),
    basePose: {
      Bone.spine: BoneTransform(rotDeg: 4),
      Bone.farmL: BoneTransform(rotDeg: -70),
      Bone.farmR: BoneTransform(rotDeg: -70),
    },
    tracks: {
      Bone.root: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.25, BoneTransform(dy: -2.5)),
        Keyframe(0.5, _zero),
        Keyframe(0.75, BoneTransform(dy: -2.5)),
        Keyframe(1, _zero),
      ]),
      Bone.thighL: Track.swing(-90, 0),
      Bone.shinL: Track.swing(90, 0),
      Bone.thighR: Track.swing(0, -90),
      Bone.shinR: Track.swing(0, 90),
      Bone.uarmL: Track.swing(30, -30),
    },
    mirrors: [Mirror(Bone.uarmR, from: Bone.uarmL)],
  );

  // ===== 核心 =====

  /// 卷腹(侧面):仰卧,屈膝脚着地,上身卷起 25°,双手抱头。
  static const crunch = MotionClip(
    id: 'crunch',
    facing: Facing.side,
    period: Duration(milliseconds: 1400),
    stage: _supine,
    basePose: {
      Bone.thighL: BoneTransform(rotDeg: -45),
      Bone.shinL: BoneTransform(rotDeg: 90),
      Bone.thighR: BoneTransform(rotDeg: -45),
      Bone.shinR: BoneTransform(rotDeg: 90),
      Bone.uarmL: BoneTransform(rotDeg: -150),
      Bone.farmL: BoneTransform(rotDeg: -20),
      Bone.uarmR: BoneTransform(rotDeg: -150),
      Bone.farmR: BoneTransform(rotDeg: -20),
    },
    tracks: {Bone.spine: Track.swing(0, 25), Bone.head: Track.swing(0, 15)},
    effects: [ClipEffect.aura(rx: 26)],
  );

  /// 仰卧举腿(侧面):仰卧,双臂贴身,直腿从地面抬到 80°。
  static const legRaise = MotionClip(
    id: 'leg_raise',
    facing: Facing.side,
    period: Duration(milliseconds: 1600),
    stage: _supine,
    tracks: {
      Bone.thighL: Track.swing(0, -80),
      Bone.thighR: Track.swing(0, -80),
      Bone.head: Track.swing(0, 5),
    },
    effects: [ClipEffect.aura(rx: 26)],
  );

  // ===== 柔韧 =====

  /// 猫牛式(侧面):跪撑,脊柱 ∓8 拱/塌,头随之抬低,整体微起伏。
  static const catCow = MotionClip(
    id: 'cat_cow',
    facing: Facing.side,
    period: Duration(milliseconds: 2400),
    stage: StageTransform(
      pivot: Offset(40, 50),
      rotDeg: 90,
      translate: Offset(-3, 24),
    ),
    basePose: {
      Bone.uarmL: BoneTransform(rotDeg: -90),
      Bone.farmL: BoneTransform(rotDeg: 60),
      Bone.uarmR: BoneTransform(rotDeg: -90),
      Bone.farmR: BoneTransform(rotDeg: 60),
      Bone.thighL: BoneTransform(rotDeg: -90),
      Bone.thighR: BoneTransform(rotDeg: -90),
    },
    tracks: {
      Bone.spine: Track.swing(-8, 8),
      Bone.head: Track.swing(10, -25),
      Bone.root: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: 3)),
        Keyframe(1, _zero),
      ]),
    },
    effects: [ClipEffect.aura(rx: 26)],
  );

  /// 站立前屈(侧面):上身前折 75°(顶点停 20%),双臂垂向地面。
  static const forwardFold = MotionClip(
    id: 'forward_fold',
    facing: Facing.side,
    period: Duration(milliseconds: 2600),
    tracks: {
      Bone.spine: Track.hold(0, 75),
      Bone.head: Track.hold(0, 15),
      Bone.uarmL: Track.hold(0, -70),
      Bone.uarmR: Track.hold(0, -70),
    },
  );

  static const all = [
    lunge,
    pushup,
    jumpingJack,
    highKnees,
    crunch,
    legRaise,
    catCow,
    forwardFold,
  ];
}

import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../../../core/theme/cofit_colors.dart';
import '../../../../../core/theme/cofit_dimens.dart';
import '../rig/bone.dart';
import '../rig/bone_transform.dart';
import '../rig/motion_clip.dart';
import '../rig/track.dart';

/// 8 个基础状态的 clip 数据(docs/avatar_bean_spec.md §5)。
/// 角度顺时针为正;loop clip 首尾帧相同,保证相位偏移下无跳变。
abstract final class CoreStateClips {
  static const _zero = BoneTransform.identity;

  /// 待机:root 浮动 −5 + 蛋体呼吸。周期走全局 token(bob 与光圈呼吸同节奏)。
  static const idle = MotionClip(
    id: 'idle',
    facing: Facing.front,
    period: CoFitMotion.bobPeriod,
    tracks: {
      Bone.root: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: -5)),
        Keyframe(1, _zero),
      ]),
      Bone.spine: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(scaleX: 0.985, scaleY: 1.03)),
        Keyframe(1, _zero),
      ]),
    },
  );

  /// 站立待机(今日面板台上):脚踩台面,无上下浮动,只保留蛋体呼吸。
  /// 与漂浮待机同周期,切换时呼吸节奏不变。
  static const idleStand = MotionClip(
    id: 'idle_stand',
    facing: Facing.front,
    period: CoFitMotion.bobPeriod,
    tracks: {
      Bone.spine: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(scaleX: 0.985, scaleY: 1.03)),
        Keyframe(1, _zero),
      ]),
    },
  );

  /// 上台 ×1(avatarBoard = 蓄力 90 + 腾空 250 + 落地 180):
  /// 0–17% 下蹲蓄力,17–65% 腾空拉长、双臂外张,65% 触地压扁 + burst,之后回弹。
  /// 位移由房间页的位置层负责,这里只有姿势;时间点与 stage* token 对应。
  static const board = MotionClip(
    id: 'board',
    facing: Facing.front,
    period: CoFitMotion.avatarBoard,
    loop: false,
    tracks: {
      Bone.spine: Track.keys([
        Keyframe(0, _zero, curve: Curves.easeOut),
        Keyframe(0.17, BoneTransform(scaleX: 1.1, scaleY: 0.88)),
        Keyframe(0.3, BoneTransform(scaleX: 0.95, scaleY: 1.07)),
        Keyframe(
          0.65,
          BoneTransform(scaleX: 0.95, scaleY: 1.07),
          curve: Curves.easeOut,
        ),
        Keyframe(0.78, BoneTransform(scaleX: 1.12, scaleY: 0.86)),
        Keyframe(0.92, BoneTransform(scaleX: 0.98, scaleY: 1.03)),
        Keyframe(1, _zero),
      ]),
      Bone.uarmL: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.17, BoneTransform(rotDeg: -8), curve: Curves.easeOut),
        Keyframe(0.35, BoneTransform(rotDeg: 36)),
        Keyframe(0.65, BoneTransform(rotDeg: 36), curve: Curves.easeOut),
        Keyframe(0.8, BoneTransform(rotDeg: 16)),
        Keyframe(1, _zero),
      ]),
    },
    mirrors: [Mirror(Bone.uarmR, from: Bone.uarmL)],
    effects: [ClipEffect.aura(), ClipEffect.burst(start: 0.65, speed: 2.8)],
  );

  /// 下台 ×1(avatarLeave = 蓄力 90 + 腾空 310 + 落定 80):
  /// 0–19% 下蹲蓄力,19–83% 腾空拉长,末尾回到漂浮待机的起始姿势。
  static const leave = MotionClip(
    id: 'leave',
    facing: Facing.front,
    period: CoFitMotion.avatarLeave,
    loop: false,
    tracks: {
      Bone.spine: Track.keys([
        Keyframe(0, _zero, curve: Curves.easeOut),
        Keyframe(0.19, BoneTransform(scaleX: 1.12, scaleY: 0.86)),
        Keyframe(0.33, BoneTransform(scaleX: 0.94, scaleY: 1.08)),
        Keyframe(0.7, BoneTransform(scaleX: 0.94, scaleY: 1.08)),
        Keyframe(0.83, _zero),
        Keyframe(1, _zero),
      ]),
      Bone.uarmL: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.19, BoneTransform(rotDeg: -8), curve: Curves.easeOut),
        Keyframe(0.36, BoneTransform(rotDeg: 30)),
        Keyframe(0.83, _zero),
        Keyframe(1, _zero),
      ]),
    },
    mirrors: [Mirror(Bone.uarmR, from: Bone.uarmL)],
  );

  /// 起手 ×1:整体 1→1.16→1 回弹(自脚底放大),双臂外张 40°,burst。
  static const windup = MotionClip(
    id: 'windup',
    facing: Facing.front,
    period: CoFitMotion.avatarWindup,
    loop: false,
    tracks: {
      Bone.root: Track.sampled(_windupScale),
      Bone.uarmL: Track.keys([
        Keyframe(0, _zero, curve: Curves.easeOut),
        Keyframe(0.5, BoneTransform(rotDeg: 40), curve: Curves.easeIn),
        Keyframe(1, _zero),
      ]),
    },
    mirrors: [Mirror(Bone.uarmR, from: Bone.uarmL)],
    effects: [ClipEffect.aura(), ClipEffect.burst()],
  );

  static BoneTransform _windupScale(double t) {
    final s = 1 + 0.16 * math.sin(math.pi * Curves.easeOut.transform(t));
    return BoneTransform(scaleX: s, scaleY: s);
  }

  /// 力量·深蹲(侧面):骨盆下沉 7,大腿 −82 / 小腿 88,上身前倾 24,双臂前平举。
  static const squat = MotionClip(
    id: 'squat',
    facing: Facing.side,
    period: Duration(milliseconds: 1300),
    tracks: {
      Bone.pelvis: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: 7)),
        Keyframe(1, _zero),
      ]),
      Bone.thighL: Track.swing(0, -82),
      Bone.thighR: Track.swing(0, -82),
      Bone.shinL: Track.swing(0, 88),
      Bone.shinR: Track.swing(0, 88),
      Bone.spine: Track.swing(0, 24),
      Bone.uarmL: Track.swing(0, -95),
      Bone.uarmR: Track.swing(0, -95),
      Bone.farmL: Track.swing(0, -8),
      Bone.farmR: Track.swing(0, -8),
      Bone.head: Track.swing(0, -20),
    },
  );

  /// 有氧·原地跑(侧面):hop 2 倍频,前倾 8°,腿 ±32 交替 + 膝弯 10→55,臂 ±35 反相。
  static const run = MotionClip(
    id: 'run_in_place',
    facing: Facing.side,
    period: Duration(milliseconds: 600),
    basePose: {
      Bone.spine: BoneTransform(rotDeg: 8),
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
      Bone.thighL: Track.swing(-32, 32),
      Bone.shinL: Track.swing(10, 55),
      Bone.shinR: Track.swing(55, 10),
      Bone.uarmL: Track.swing(35, -35),
    },
    mirrors: [
      Mirror(Bone.thighR, from: Bone.thighL),
      Mirror(Bone.uarmR, from: Bone.uarmL),
    ],
  );

  /// 核心·平板(侧面):整体绕 (40,50) 转 90° 卧倒并平移,手臂垂直撑地,微颤 1.6。
  static const plank = MotionClip(
    id: 'plank',
    facing: Facing.side,
    period: Duration(milliseconds: 900),
    stage: StageTransform(
      pivot: Offset(40, 50),
      rotDeg: 90,
      translate: Offset(-3, 20),
    ),
    basePose: {
      Bone.uarmL: BoneTransform(rotDeg: -90),
      Bone.uarmR: BoneTransform(rotDeg: -90),
      Bone.head: BoneTransform(rotDeg: -12),
    },
    tracks: {
      Bone.root: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.5, BoneTransform(dy: 1.6)),
        Keyframe(1, _zero),
      ]),
    },
    effects: [ClipEffect.aura(rx: 26)],
  );

  /// 柔韧·体侧伸展(正面):上身 0→−16 顶点停 20%,右臂固定过头,站宽。
  static const stretch = MotionClip(
    id: 'side_stretch',
    facing: Facing.front,
    period: Duration(milliseconds: 2600),
    basePose: {
      Bone.uarmR: BoneTransform(rotDeg: -150),
      Bone.farmR: BoneTransform(rotDeg: -20),
      Bone.thighL: BoneTransform(rotDeg: 10),
      Bone.thighR: BoneTransform(rotDeg: -10),
    },
    tracks: {
      Bone.spine: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.4, BoneTransform(rotDeg: -16), curve: Curves.linear),
        Keyframe(0.6, BoneTransform(rotDeg: -16)),
        Keyframe(1, _zero),
      ]),
      Bone.head: Track.keys([
        Keyframe(0, _zero),
        Keyframe(0.4, BoneTransform(rotDeg: 8), curve: Curves.linear),
        Keyframe(0.6, BoneTransform(rotDeg: 8)),
        Keyframe(1, _zero),
      ]),
    },
  );

  /// 暂停:绕脚底 ±5° 摇摆,整体 75%。
  static const paused = MotionClip(
    id: 'paused',
    facing: Facing.front,
    period: CoFitMotion.avatarLoopPaused,
    opacity: CoFitOpacities.pausedFigure,
    tracks: {Bone.root: Track.swing(-5, 5)},
  );

  /// 完成 ×1:跳 −16 + 二段 −6,蛋体挤压拉伸,双臂 150° 过头,burst ×2。
  static const finish = MotionClip(
    id: 'finish',
    facing: Facing.front,
    period: CoFitMotion.avatarFinish,
    loop: false,
    tracks: {
      Bone.root: Track.sampled(_finishJump),
      Bone.spine: Track.keys([
        Keyframe(0, _zero, curve: Curves.easeOut),
        Keyframe(0.18, BoneTransform(scaleX: 0.94, scaleY: 1.08)),
        Keyframe(0.55, BoneTransform(scaleX: 1.06, scaleY: 0.94)),
        Keyframe(0.73, _zero),
        Keyframe(1, _zero),
      ]),
      Bone.uarmL: Track.sampled(_finishArm),
    },
    mirrors: [Mirror(Bone.uarmR, from: Bone.uarmL)],
    effects: [
      ClipEffect.aura(),
      ClipEffect.burst(speed: 1.6),
      ClipEffect.burst(start: 0.12, speed: 1.6),
    ],
  );

  static BoneTransform _finishJump(double t) {
    // 主跳 + 二段小跳(README:跳 −16px + 二段小跳)
    if (t < 0.55) {
      return BoneTransform(dy: -16 * math.sin(math.pi * t / 0.55));
    }
    if (t < 0.85) {
      return BoneTransform(dy: -6 * math.sin(math.pi * (t - 0.55) / 0.3));
    }
    return BoneTransform.identity;
  }

  static BoneTransform _finishArm(double t) {
    final progress = Curves.easeOutBack.transform((t / 0.35).clamp(0.0, 1.0));
    return BoneTransform(rotDeg: 150 * progress);
  }
}

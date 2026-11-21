import '../../../action/domain/entity/action_type.dart';
import '../../domain/entity/avatar_motion.dart';
import 'clips/core_states.dart';
import 'clips/exercise_clips.dart';
import 'rig/motion_clip.dart';

/// 动画指令 → clip 的查找表。P2 起 `AvatarMotion.motionId` 优先,
/// 未命中回类型原型;再未命中回 strength 原型(与 `ActionType.fallback` 一致)。
abstract final class MotionClipLibrary {
  static const Map<ActionType, MotionClip> prototypes = {
    ActionType.strength: CoreStateClips.squat,
    ActionType.cardio: CoreStateClips.run,
    ActionType.core: CoreStateClips.plank,
    ActionType.flexibility: CoreStateClips.stretch,
  };

  static const List<MotionClip> all = [
    CoreStateClips.idle,
    CoreStateClips.windup,
    CoreStateClips.squat,
    CoreStateClips.run,
    CoreStateClips.plank,
    CoreStateClips.stretch,
    CoreStateClips.paused,
    CoreStateClips.finish,
    CoreStateClips.idleStand,
    CoreStateClips.board,
    CoreStateClips.leave,
    ...ExerciseClips.all,
  ];

  /// 可被卡片选用的动作(排除 idle/windup/paused/finish/上台下台 这类状态 clip)。
  static List<MotionClip> get exercises => all
      .where(
        (c) =>
            c != CoreStateClips.idle &&
            c != CoreStateClips.windup &&
            c != CoreStateClips.paused &&
            c != CoreStateClips.finish &&
            c != CoreStateClips.idleStand &&
            c != CoreStateClips.board &&
            c != CoreStateClips.leave,
      )
      .toList(growable: false);

  /// 动作所属类型(原型 = 该类型;其余按 id 表),给选择器分组用。
  static const Map<String, ActionType> typeOf = {
    'squat': ActionType.strength,
    'lunge': ActionType.strength,
    'pushup': ActionType.strength,
    'run_in_place': ActionType.cardio,
    'jumping_jack': ActionType.cardio,
    'high_knees': ActionType.cardio,
    'plank': ActionType.core,
    'crunch': ActionType.core,
    'leg_raise': ActionType.core,
    'side_stretch': ActionType.flexibility,
    'cat_cow': ActionType.flexibility,
    'forward_fold': ActionType.flexibility,
  };

  /// 动作中文名(选择器/详情用;SSOT 卡名可能不同,这里是动作本身的名字)。
  static const Map<String, String> nameOf = {
    'squat': '深蹲',
    'lunge': '弓步蹲',
    'pushup': '俯卧撑',
    'run_in_place': '原地跑',
    'jumping_jack': '开合跳',
    'high_knees': '高抬腿',
    'plank': '平板支撑',
    'crunch': '卷腹',
    'leg_raise': '仰卧举腿',
    'side_stretch': '体侧伸展',
    'cat_cow': '猫牛式',
    'forward_fold': '站立前屈',
  };

  static MotionClip? byId(String? id) {
    if (id == null) {
      return null;
    }
    for (final clip in all) {
      if (clip.id == id) {
        return clip;
      }
    }
    return null;
  }

  static MotionClip resolve(AvatarMotion motion) {
    return switch (motion.state) {
      AvatarMotionState.idle =>
        motion.grounded ? CoreStateClips.idleStand : CoreStateClips.idle,
      AvatarMotionState.board => CoreStateClips.board,
      AvatarMotionState.leave => CoreStateClips.leave,
      AvatarMotionState.windup => CoreStateClips.windup,
      AvatarMotionState.paused => CoreStateClips.paused,
      AvatarMotionState.finish => CoreStateClips.finish,
      AvatarMotionState.exercise =>
        byId(motion.motionId) ??
            prototypes[motion.actionType ?? ActionType.fallback]!,
    };
  }
}

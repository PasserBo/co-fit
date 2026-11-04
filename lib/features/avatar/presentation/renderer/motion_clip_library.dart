import '../../../action/domain/entity/action_type.dart';
import '../../domain/entity/avatar_motion.dart';
import 'clips/core_states.dart';
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
  ];

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
      AvatarMotionState.idle => CoreStateClips.idle,
      AvatarMotionState.windup => CoreStateClips.windup,
      AvatarMotionState.paused => CoreStateClips.paused,
      AvatarMotionState.finish => CoreStateClips.finish,
      AvatarMotionState.exercise =>
        prototypes[motion.actionType ?? ActionType.fallback]!,
    };
  }
}

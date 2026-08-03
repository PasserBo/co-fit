import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../action/domain/entity/action_type.dart';

part 'avatar_motion.freezed.dart';

/// 小人动画状态机的状态(README §小人动作动画):
/// idle →(打出)→ windup ×1 → exercise loop ⇄ paused →(时长结束)→ finish ×1 → idle。
enum AvatarMotionState { idle, windup, exercise, paused, finish }

/// 节奏倍率(README:慢/标准/快 → 时长 ×1.3 / ×1 / ×0.75)。
enum AvatarTempo {
  slow,
  standard,
  fast;

  /// 从卡片 intensityBaseline 的 label 推断;未知取标准。
  static AvatarTempo fromIntensityLabel(String? label) {
    if (label == null) {
      return AvatarTempo.standard;
    }
    if (label.contains('慢') || label.contains('轻')) {
      return AvatarTempo.slow;
    }
    if (label.contains('快') || label.contains('高')) {
      return AvatarTempo.fast;
    }
    return AvatarTempo.standard;
  }
}

/// 某一时刻要播放的动画指令 —— 动画实现(Flutter 原生 / 将来的 Rive)
/// 只依赖这个值对象,与业务状态解耦。
@freezed
abstract class AvatarMotion with _$AvatarMotion {
  const factory AvatarMotion({
    required AvatarMotionState state,

    /// exercise 时按 4 类型走通用原型;其他状态可为 null。
    ActionType? actionType,
    @Default(AvatarTempo.standard) AvatarTempo tempo,
  }) = _AvatarMotion;

  factory AvatarMotion.idle() =>
      const AvatarMotion(state: AvatarMotionState.idle);
}

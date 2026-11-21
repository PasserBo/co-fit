import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../action/domain/entity/action_type.dart';

part 'avatar_motion.freezed.dart';

/// 小人动画状态机的状态(README §小人动作动画):
/// idle →(打出)→ windup ×1 → exercise loop ⇄ paused →(时长结束)→ finish ×1 → idle。
///
/// 今日面板(add-home-sheet):待机时上台 / 下台各有一个 ×1 反应
/// idle(漂浮)→ board ×1 → idle(grounded,站立)→ leave ×1 → idle(漂浮)。
enum AvatarMotionState { idle, windup, exercise, paused, finish, board, leave }

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

    /// exercise 时的类型(clip 未命中时的原型兜底);其他状态可为 null。
    ActionType? actionType,

    /// exercise 时的具体动作 clip id(P2);null/未知 → 类型原型。
    String? motionId,
    @Default(AvatarTempo.standard) AvatarTempo tempo,

    /// 是否站在今日面板上沿(台上)。只在 idle / board / leave 上有意义:
    /// idle + grounded = 站立待机(无上下浮动)。运动 / 暂停 / 起手 / 完成
    /// 不带此标记,所以上台不会重启正在播放的 clip。
    @Default(false) bool grounded,
  }) = _AvatarMotion;

  factory AvatarMotion.idle() =>
      const AvatarMotion(state: AvatarMotionState.idle);
}

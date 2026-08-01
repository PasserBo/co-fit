import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_activity_status_entity.dart';

part 'action_session.freezed.dart';

enum ActionSessionStatus { active, paused, completed }

/// 运动会话:事件流(RoomEvent)折叠出的「某用户此刻在做什么」。
///
/// 关键设计:进行中的动作用**时间点**(endsAt)而非计数器表示——
/// entity 只在事件到达时改变;剩余时间/是否过期是随 now 的派生规则,
/// 动画与倒计时由 UI 拿 endsAt 自行驱动。对方掉线不发 completed 时,
/// 本地也能凭 [isExpiredAt] 到点判定回待机。
@freezed
abstract class ActionSession with _$ActionSession {
  const ActionSession._();

  const factory ActionSession({
    required String sessionId,
    required String roomId,
    required String userId,

    /// 动作标识(将来映射 Rive 动画状态机)。
    required String actionKey,
    String? templateId,
    String? templateName,
    required int durationSec,
    required DateTime startedAt,
    required ActionSessionStatus status,

    /// active 时非空:动画/倒计时终点。
    DateTime? endsAt,

    /// paused 时非空:冻结的剩余秒数。
    int? pausedRemainingSec,

    /// 最后一次生效事件的时刻,乱序/陈旧事件判定用。
    required DateTime lastEventAt,
  }) = _ActionSession;

  int remainingSecAt(DateTime now) {
    switch (status) {
      case ActionSessionStatus.paused:
        return pausedRemainingSec ?? 0;
      case ActionSessionStatus.completed:
        return 0;
      case ActionSessionStatus.active:
        final ends = endsAt;
        if (ends == null) {
          return 0;
        }
        final seconds = ends.difference(now).inSeconds;
        return seconds < 0 ? 0 : seconds;
    }
  }

  /// active 且已越过终点(未收到 completed,本地判定过期)。
  bool isExpiredAt(DateTime now) {
    final ends = endsAt;
    return status == ActionSessionStatus.active &&
        ends != null &&
        now.isAfter(ends);
  }

  UserActivityState effectiveStateAt(DateTime now) {
    switch (status) {
      case ActionSessionStatus.completed:
        return UserActivityState.idle;
      case ActionSessionStatus.paused:
        return UserActivityState.paused;
      case ActionSessionStatus.active:
        return isExpiredAt(now)
            ? UserActivityState.idle
            : UserActivityState.active;
    }
  }

  /// 转换为 presence 通道使用的状态快照——事件流与 presence 两条通道
  /// 输出同一形状,消费端(RoomScene/HUD)无需区分来源。
  UserActivityStatusEntity toActivityStatus(DateTime now) {
    return UserActivityStatusEntity(
      activityState: effectiveStateAt(now),
      actionKey: actionKey.isEmpty ? null : actionKey,
      durationSec: durationSec,
      remainingSec: remainingSecAt(now),
      sessionId: sessionId.isEmpty ? null : sessionId,
      templateId: templateId,
      templateName: templateName,
      updatedAtEpochMs: lastEventAt.millisecondsSinceEpoch,
    );
  }
}

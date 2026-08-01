import 'package:freezed_annotation/freezed_annotation.dart';

import 'action_session.dart';
import 'room_event.dart';
import 'user_activity_status_entity.dart';

part 'room_activity_snapshot.freezed.dart';

/// 房间活动快照:某房间事件流折叠出的「每个用户当前会话」。
/// 不变式:一人同房间最多一个会话(新 started 覆盖旧会话)。
/// 多房间由 provider 层维护 `Map<roomId, RoomActivitySnapshot>`(同 presenceByRoom 模式)。
@freezed
abstract class RoomActivitySnapshot with _$RoomActivitySnapshot {
  const RoomActivitySnapshot._();

  const factory RoomActivitySnapshot({
    required String roomId,
    @Default(<String, ActionSession>{})
    Map<String, ActionSession> sessionsByUser,
  }) = _RoomActivitySnapshot;

  /// completed 会话保留时长(给 UI 播完成动画的窗口),由 [sweep] 移除。
  static const completedRetention = Duration(seconds: 5);

  /// 过期 active 会话(对方掉线未发 completed)的清扫宽限。
  static const expiredRetention = Duration(seconds: 5);

  /// 纯函数折叠一条事件。规则:
  /// - 事件时刻不晚于该用户当前会话的 lastEventAt → 视为乱序/重复,忽略;
  /// - started → 覆盖现有会话(一人一会话);
  /// - paused/resumed/completed 针对未知会话(中途进房/丢事件)→
  ///   用 payload 自举出部分会话(事件带 actionKey/durationSec/remainingSec,字段足够);
  /// - 非动作事件类型 → 原样返回。
  RoomActivitySnapshot apply(RoomEvent event) {
    if (event.roomId != roomId) {
      return this;
    }
    if (!_isActionEvent(event.type)) {
      return this;
    }

    final current = sessionsByUser[event.userId];
    if (current != null && !event.timestamp.isAfter(current.lastEventAt)) {
      return this;
    }

    final next = _applyToSession(current, event);
    if (next == null) {
      return this;
    }
    return copyWith(
      sessionsByUser: {...sessionsByUser, event.userId: next},
    );
  }

  /// 清扫:completed 超过保留期、或过期 active 超过宽限期的会话移除。
  /// 无变化时返回自身(便于 provider 判等短路)。
  RoomActivitySnapshot sweep(DateTime now) {
    final kept = <String, ActionSession>{};
    var removed = false;
    for (final entry in sessionsByUser.entries) {
      final session = entry.value;
      final completedTooOld =
          session.status == ActionSessionStatus.completed &&
              now.difference(session.lastEventAt) > completedRetention;
      final expiredTooOld = session.isExpiredAt(now) &&
          now.difference(session.endsAt!) > expiredRetention;
      if (completedTooOld || expiredTooOld) {
        removed = true;
      } else {
        kept[entry.key] = session;
      }
    }
    return removed ? copyWith(sessionsByUser: kept) : this;
  }

  /// 该用户当前状态快照;无会话时为 null(消费端 fallback 到 presence)。
  UserActivityStatusEntity? activityStatusOf(String userId, DateTime now) {
    return sessionsByUser[userId]?.toActivityStatus(now);
  }

  bool get isEmpty => sessionsByUser.isEmpty;

  static bool _isActionEvent(String type) {
    return type == RoomEventType.actionStarted ||
        type == RoomEventType.actionPaused ||
        type == RoomEventType.actionResumed ||
        type == RoomEventType.actionCompleted;
  }

  ActionSession? _applyToSession(ActionSession? current, RoomEvent event) {
    final payload = event.payload;
    final sameSession =
        current != null && current.sessionId == payload.sessionId;

    // 未知会话的自举基础:字段尽量取 payload,startedAt 用事件时刻近似。
    ActionSession bootstrap(ActionSessionStatus status) {
      return ActionSession(
        sessionId: payload.sessionId,
        roomId: roomId,
        userId: event.userId,
        actionKey: payload.actionKey,
        templateId: payload.customData['templateId']?.toString(),
        templateName: payload.customData['templateName']?.toString(),
        durationSec: payload.durationSec,
        startedAt: event.timestamp,
        status: status,
        lastEventAt: event.timestamp,
      );
    }

    switch (event.type) {
      case RoomEventType.actionStarted:
        final duration =
            payload.durationSec > 0 ? payload.durationSec : payload.remainingSec;
        return bootstrap(ActionSessionStatus.active).copyWith(
          durationSec: duration,
          endsAt: event.timestamp.add(Duration(seconds: duration)),
        );

      case RoomEventType.actionPaused:
        final base = sameSession ? current : bootstrap(ActionSessionStatus.paused);
        final remaining = payload.remainingSec > 0
            ? payload.remainingSec
            : base.remainingSecAt(event.timestamp);
        return base.copyWith(
          status: ActionSessionStatus.paused,
          pausedRemainingSec: remaining,
          endsAt: null,
          lastEventAt: event.timestamp,
        );

      case RoomEventType.actionResumed:
        final base = sameSession ? current : bootstrap(ActionSessionStatus.active);
        final remaining = payload.remainingSec > 0
            ? payload.remainingSec
            : (base.pausedRemainingSec ?? payload.durationSec);
        return base.copyWith(
          status: ActionSessionStatus.active,
          pausedRemainingSec: null,
          endsAt: event.timestamp.add(Duration(seconds: remaining)),
          lastEventAt: event.timestamp,
        );

      case RoomEventType.actionCompleted:
        final base =
            sameSession ? current : bootstrap(ActionSessionStatus.completed);
        return base.copyWith(
          status: ActionSessionStatus.completed,
          pausedRemainingSec: null,
          endsAt: null,
          lastEventAt: event.timestamp,
        );

      default:
        return null;
    }
  }
}

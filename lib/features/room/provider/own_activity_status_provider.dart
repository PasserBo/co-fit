import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/user_activity_status_entity.dart';

/// 自己当前 presence.activity 的单一事实源(null = idle)。
/// 写入方:action 的 OwnActionSessionNotifier(play/complete);
/// 读取方:AblyRuntimeNotifier(重连重申、进新房间时带上 activity)。
/// 放在 room 特性:实体属于 room domain,且 firestore 层已依赖 room,
/// 避免 firestore ↔ action 的循环依赖。
class OwnActivityStatusNotifier extends Notifier<UserActivityStatusEntity?> {
  @override
  UserActivityStatusEntity? build() => null;

  void set(UserActivityStatusEntity? status) {
    state = status;
  }
}

final ownActivityStatusProvider =
    NotifierProvider<OwnActivityStatusNotifier, UserActivityStatusEntity?>(
  OwnActivityStatusNotifier.new,
);

/// 把 activity 状态"重申"到 now:
/// - active:按 updatedAtEpochMs + remainingSec 推算 endsAt;
///   未到点 → 刷新 remainingSec/updatedAtEpochMs(接收端 applyPresenceStatus
///   要求 updatedAt 严格新于快照,否则静默丢弃);到点/字段缺失 → idle。
/// - 其他状态:仅刷新 updatedAtEpochMs。
UserActivityStatusEntity reassertActivityStatusAt(
  UserActivityStatusEntity status,
  DateTime now,
) {
  final nowMs = now.millisecondsSinceEpoch;
  if (status.activityState != UserActivityState.active) {
    return status.copyWith(updatedAtEpochMs: nowMs);
  }
  final updatedAtMs = status.updatedAtEpochMs;
  final remainingSec = status.remainingSec;
  if (updatedAtMs == null || remainingSec == null) {
    return UserActivityStatusEntity(
      activityState: UserActivityState.idle,
      updatedAtEpochMs: nowMs,
    );
  }
  final endsAtMs = updatedAtMs + remainingSec * 1000;
  if (nowMs >= endsAtMs) {
    return UserActivityStatusEntity(
      activityState: UserActivityState.idle,
      updatedAtEpochMs: nowMs,
    );
  }
  final nextRemainingSec = ((endsAtMs - nowMs) / 1000).ceil();
  return status.copyWith(
    remainingSec: nextRemainingSec,
    updatedAtEpochMs: nowMs,
  );
}

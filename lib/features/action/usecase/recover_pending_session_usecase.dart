import '../domain/action_session_history_repository.dart';
import '../domain/entity/action_session_record.dart';
import '../domain/entity/pending_session_snapshot.dart';
import '../domain/pending_session_repository.dart';

/// 恢复结果:无 / 已过期并补记打卡 / 仍在进行(由调用方恢复计时与 presence)。
sealed class PendingSessionRecovery {
  const PendingSessionRecovery();
}

class NoPendingSession extends PendingSessionRecovery {
  const NoPendingSession();
}

class ExpiredSessionRecorded extends PendingSessionRecovery {
  const ExpiredSessionRecorded(this.record);
  final ActionSessionRecord record;
}

class SessionStillRunning extends PendingSessionRecovery {
  const SessionStillRunning(this.snapshot);
  final PendingSessionSnapshot snapshot;
}

/// 冷启动 / 重新登录时调用:
/// - 快照不属于当前用户 → 丢弃;
/// - endsAt 已过 → 以 endsAt 为 completedAt 补记一条打卡(修复「会话中被杀则记录丢失」),清快照;
/// - 仍在进行 → 原样返回,调用方恢复倒计时与 presence(快照保留,完成时再清)。
/// 补记失败时**保留快照**,下次启动再试。
class RecoverPendingSessionUsecase {
  RecoverPendingSessionUsecase(
    this._pending,
    this._history, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PendingSessionRepository _pending;
  final ActionSessionHistoryRepository _history;
  final DateTime Function() _now;

  Future<PendingSessionRecovery> execute({required String userId}) async {
    final snapshot = await _pending.load();
    if (snapshot == null) {
      return const NoPendingSession();
    }
    if (snapshot.userId != userId) {
      await _pending.clear();
      return const NoPendingSession();
    }
    final now = _now();
    if (!snapshot.isExpiredAt(now)) {
      return SessionStillRunning(snapshot);
    }
    final record = ActionSessionRecord(
      sessionId: snapshot.sessionId,
      roomId: snapshot.roomId,
      userId: snapshot.userId,
      templateId: snapshot.templateId,
      templateName: snapshot.templateName,
      actionKey: snapshot.actionKey,
      durationSec: snapshot.durationSec,
      startedAt: snapshot.startedAt,
      completedAt: snapshot.endsAt,
    );
    await _history.recordSession(record);
    await _pending.clear();
    return ExpiredSessionRecorded(record);
  }
}

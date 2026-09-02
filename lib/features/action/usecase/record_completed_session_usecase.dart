import '../domain/action_session_history_repository.dart';
import '../domain/entity/action_session_record.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/entity/template_card_session.dart';

/// 会话完成后落库打卡记录(users/{uid}/sessions)。
/// 由 OwnActionSessionNotifier.complete() fire-and-forget 调用,
/// 失败不阻塞 UI 与 presence 流。
class RecordCompletedSessionUsecase {
  RecordCompletedSessionUsecase(
    this._repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ActionSessionHistoryRepository _repository;
  final DateTime Function() _now;

  Future<ActionSessionRecord> execute({
    required TemplateCardSession session,
    required ActionTemplateCard card,
  }) async {
    final record = ActionSessionRecord(
      sessionId: session.sessionId,
      roomId: session.roomId,
      userId: session.userId,
      templateId: session.templateId,
      templateName: card.name,
      actionKey: card.rawType,
      durationSec: card.defaultDurationSec,
      startedAt: session.startedAt,
      completedAt: _now(),
    );
    await _repository.recordSession(record);
    return record;
  }
}

import 'package:cofit/features/action/domain/action_session_history_repository.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/domain/entity/template_card_session.dart';
import 'package:cofit/features/action/usecase/record_completed_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoryRepository implements ActionSessionHistoryRepository {
  final List<ActionSessionRecord> recorded = [];
  Object? throwOnRecord;

  @override
  Future<void> recordSession(ActionSessionRecord record) async {
    if (throwOnRecord != null) {
      throw throwOnRecord!;
    }
    recorded.add(record);
  }

  @override
  Future<List<ActionSessionRecord>> fetchRecentSessions({
    required String userId,
    int limit = 100,
  }) async {
    return recorded;
  }
}

void main() {
  final startedAt = DateTime(2026, 8, 10, 9, 30);
  final completedAt = DateTime(2026, 8, 10, 9, 31);

  final session = TemplateCardSession(
    templateId: 'template-1',
    sessionId: 'session-1',
    roomId: 'room-1',
    userId: 'user-1',
    status: TemplateCardSessionStatus.completed,
    startedAt: startedAt,
  );

  const card = ActionTemplateCard(
    id: 'template-1',
    name: '深蹲',
    type: ActionType.strength,
    rawType: 'strength',
    source: ActionSource.official,
    ablyActionId: 'squat',
    defaultDurationSec: 60,
    intensityBaseline: {},
  );

  test('maps session + card into a completed record', () async {
    final repository = _FakeHistoryRepository();
    final usecase = RecordCompletedSessionUsecase(
      repository,
      now: () => completedAt,
    );

    final record = await usecase.execute(session: session, card: card);

    expect(repository.recorded, hasLength(1));
    expect(record.sessionId, 'session-1');
    expect(record.roomId, 'room-1');
    expect(record.userId, 'user-1');
    expect(record.templateId, 'template-1');
    expect(record.templateName, '深蹲');
    expect(record.actionKey, 'strength');
    expect(record.durationSec, 60);
    expect(record.startedAt, startedAt);
    expect(record.completedAt, completedAt);
    expect(record.status, ActionSessionRecordStatus.completed);
  });

  test('propagates repository failure (caller decides fire-and-forget)',
      () async {
    final repository = _FakeHistoryRepository()
      ..throwOnRecord = StateError('firestore down');
    final usecase = RecordCompletedSessionUsecase(
      repository,
      now: () => completedAt,
    );

    await expectLater(
      usecase.execute(session: session, card: card),
      throwsStateError,
    );
  });
}

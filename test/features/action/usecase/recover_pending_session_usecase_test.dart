import 'package:cofit/features/action/data/in_memory_pending_session_repository.dart';
import 'package:cofit/features/action/domain/action_session_history_repository.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/domain/entity/pending_session_snapshot.dart';
import 'package:cofit/features/action/usecase/recover_pending_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistory implements ActionSessionHistoryRepository {
  final recorded = <ActionSessionRecord>[];
  Object? throwOnRecord;

  @override
  Future<void> recordSession(ActionSessionRecord record) async {
    if (throwOnRecord != null) throw throwOnRecord!;
    recorded.add(record);
  }

  @override
  Future<List<ActionSessionRecord>> fetchRecentSessions({
    required String userId,
    int limit = 100,
  }) async => recorded;
}

void main() {
  final startedAt = DateTime(2026, 10, 26, 9, 0);
  final snapshot = PendingSessionSnapshot(
    sessionId: 's1',
    roomId: 'r1',
    userId: 'u1',
    templateId: 't1',
    templateName: '深蹲',
    actionKey: 'strength',
    durationSec: 600,
    startedAt: startedAt,
  );

  late InMemoryPendingSessionRepository pending;
  late _FakeHistory history;

  setUp(() {
    pending = InMemoryPendingSessionRepository();
    history = _FakeHistory();
  });

  RecoverPendingSessionUsecase usecase(DateTime now) =>
      RecoverPendingSessionUsecase(pending, history, now: () => now);

  test('no snapshot → NoPendingSession', () async {
    final result = await usecase(startedAt).execute(userId: 'u1');
    expect(result, isA<NoPendingSession>());
  });

  test('snapshot of another user is discarded', () async {
    await pending.save(snapshot);
    final result = await usecase(startedAt).execute(userId: 'someone-else');
    expect(result, isA<NoPendingSession>());
    expect(await pending.load(), isNull);
    expect(history.recorded, isEmpty);
  });

  test('still running → returned untouched, snapshot kept', () async {
    await pending.save(snapshot);
    final now = startedAt.add(const Duration(minutes: 3));
    final result = await usecase(now).execute(userId: 'u1');
    expect(result, isA<SessionStillRunning>());
    expect((result as SessionStillRunning).snapshot.remainingSecAt(now), 420);
    expect(await pending.load(), isNotNull);
    expect(history.recorded, isEmpty);
  });

  test(
    'expired → record with completedAt = endsAt, snapshot cleared',
    () async {
      await pending.save(snapshot);
      final now = startedAt.add(const Duration(hours: 2));
      final result = await usecase(now).execute(userId: 'u1');
      expect(result, isA<ExpiredSessionRecorded>());
      final record = history.recorded.single;
      expect(record.sessionId, 's1');
      expect(record.templateName, '深蹲');
      expect(record.durationSec, 600);
      expect(record.completedAt, startedAt.add(const Duration(seconds: 600)));
      expect(await pending.load(), isNull);
    },
  );

  test('exactly at endsAt counts as expired', () async {
    await pending.save(snapshot);
    final result = await usecase(
      startedAt.add(const Duration(seconds: 600)),
    ).execute(userId: 'u1');
    expect(result, isA<ExpiredSessionRecorded>());
  });

  test('record failure keeps snapshot for a later retry', () async {
    await pending.save(snapshot);
    history.throwOnRecord = StateError('offline');
    await expectLater(
      usecase(startedAt.add(const Duration(hours: 1))).execute(userId: 'u1'),
      throwsStateError,
    );
    expect(await pending.load(), isNotNull);
  });

  test('snapshot round-trips through toMap/fromMap', () {
    final parsed = PendingSessionSnapshot.fromMap(snapshot.toMap());
    expect(parsed, snapshot);
    expect(PendingSessionSnapshot.fromMap({'sessionId': ''}), isNull);
    expect(PendingSessionSnapshot.fromMap('garbage'), isNull);
  });
}

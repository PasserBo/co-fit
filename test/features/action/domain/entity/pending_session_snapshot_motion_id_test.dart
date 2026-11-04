import 'package:cofit/features/action/domain/entity/pending_session_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motionId is persisted and restored; absent key stays null', () {
    final snapshot = PendingSessionSnapshot(
      sessionId: 's1',
      roomId: 'r1',
      userId: 'u1',
      templateId: 'lunge',
      templateName: '弓步蹲',
      actionKey: 'strength',
      durationSec: 60,
      startedAt: DateTime(2026, 11, 4, 10),
      motionId: 'lunge',
    );
    final restored = PendingSessionSnapshot.fromMap(snapshot.toMap());
    expect(restored?.motionId, 'lunge');

    final legacy = PendingSessionSnapshot.fromMap({
      ...snapshot.toMap()..remove('motionId'),
    });
    expect(legacy?.motionId, isNull);
  });
}

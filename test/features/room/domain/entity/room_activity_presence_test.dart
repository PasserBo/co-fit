import 'package:cofit/features/room/domain/entity/action_session.dart';
import 'package:cofit/features/room/domain/entity/room_activity_snapshot.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 8, 2, 9, 0, 0);

UserActivityStatusEntity _status({
  UserActivityState state = UserActivityState.active,
  String? sessionId = 's1',
  int? remainingSec = 300,
  int? durationSec = 600,
  DateTime? updatedAt,
}) {
  return UserActivityStatusEntity(
    activityState: state,
    actionKey: 'strength_basic',
    durationSec: durationSec,
    remainingSec: remainingSec,
    sessionId: sessionId,
    templateName: '深蹲',
    updatedAtEpochMs: (updatedAt ?? _t0).millisecondsSinceEpoch,
  );
}

const _empty = RoomActivitySnapshot(roomId: 'room-1');

void main() {
  test('active presence snapshot bootstraps a ticking session (late joiner)',
      () {
    final snapshot =
        _empty.applyPresenceStatus(userId: 'user-a', status: _status());

    final session = snapshot.sessionsByUser['user-a']!;
    expect(session.status, ActionSessionStatus.active);
    expect(session.endsAt, _t0.add(const Duration(seconds: 300)));
    // 会随 now 递减、到点过期
    expect(session.remainingSecAt(_t0.add(const Duration(seconds: 60))), 240);
    expect(session.isExpiredAt(_t0.add(const Duration(seconds: 301))), isTrue);
  });

  test('paused presence snapshot freezes remaining', () {
    final snapshot = _empty.applyPresenceStatus(
      userId: 'user-a',
      status: _status(state: UserActivityState.paused, remainingSec: 200),
    );

    final session = snapshot.sessionsByUser['user-a']!;
    expect(session.status, ActionSessionStatus.paused);
    expect(session.pausedRemainingSec, 200);
  });

  test('presence older than the current session is ignored', () {
    final fresh = _empty.applyPresenceStatus(
      userId: 'user-a',
      status: _status(updatedAt: _t0.add(const Duration(seconds: 100))),
    );

    final stale = fresh.applyPresenceStatus(
      userId: 'user-a',
      status: _status(sessionId: 's0', updatedAt: _t0),
    );
    expect(identical(stale, fresh), isTrue);
  });

  test('newer idle presence clears the session', () {
    final active =
        _empty.applyPresenceStatus(userId: 'user-a', status: _status());

    final cleared = active.applyPresenceStatus(
      userId: 'user-a',
      status: _status(
        state: UserActivityState.idle,
        sessionId: null,
        remainingSec: null,
        durationSec: null,
        updatedAt: _t0.add(const Duration(seconds: 400)),
      ),
    );
    expect(cleared.isEmpty, isTrue);
  });

  test('snapshots without updatedAt or sessionId are no-ops', () {
    final noTimestamp = _empty.applyPresenceStatus(
      userId: 'user-a',
      status: const UserActivityStatusEntity(
        activityState: UserActivityState.active,
      ),
    );
    expect(identical(noTimestamp, _empty), isTrue);

    final noSession = _empty.applyPresenceStatus(
      userId: 'user-a',
      status: _status(sessionId: null),
    );
    expect(identical(noSession, _empty), isTrue);
  });
}

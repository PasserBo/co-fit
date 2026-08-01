import 'package:cofit/features/room/domain/entity/action_session.dart';
import 'package:cofit/features/room/domain/entity/room_activity_snapshot.dart';
import 'package:cofit/features/room/domain/entity/room_event.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 8, 1, 12, 0, 0);

RoomEvent _event({
  required String type,
  String eventId = 'e1',
  String roomId = 'room-1',
  String userId = 'user-a',
  String sessionId = 's1',
  String actionKey = 'strength_basic',
  int durationSec = 600,
  int remainingSec = 600,
  DateTime? timestamp,
  Map<String, dynamic> customData = const {
    'templateId': 'tpl_squat',
    'templateName': '深蹲',
  },
}) {
  return RoomEvent(
    eventId: eventId,
    roomId: roomId,
    userId: userId,
    type: type,
    timestamp: timestamp ?? _t0,
    payload: RoomEventPayload(
      schemaVersion: 1,
      actionKey: actionKey,
      durationSec: durationSec,
      remainingSec: remainingSec,
      sessionId: sessionId,
      customData: customData,
    ),
  );
}

const _empty = RoomActivitySnapshot(roomId: 'room-1');

void main() {
  group('apply / started', () {
    test('creates an active session with endsAt = timestamp + duration', () {
      final snapshot = _empty.apply(_event(type: RoomEventType.actionStarted));

      final session = snapshot.sessionsByUser['user-a']!;
      expect(session.status, ActionSessionStatus.active);
      expect(session.endsAt, _t0.add(const Duration(seconds: 600)));
      expect(session.templateName, '深蹲');
      expect(session.remainingSecAt(_t0.add(const Duration(seconds: 60))), 540);
      expect(session.effectiveStateAt(_t0), UserActivityState.active);
    });

    test('a newer started replaces the previous session (one per user)', () {
      final snapshot = _empty
          .apply(_event(type: RoomEventType.actionStarted))
          .apply(_event(
            type: RoomEventType.actionStarted,
            sessionId: 's2',
            actionKey: 'core_plank',
            timestamp: _t0.add(const Duration(seconds: 30)),
          ));

      final session = snapshot.sessionsByUser['user-a']!;
      expect(session.sessionId, 's2');
      expect(session.actionKey, 'core_plank');
    });

    test('members fold independently', () {
      final snapshot = _empty
          .apply(_event(type: RoomEventType.actionStarted))
          .apply(_event(
            type: RoomEventType.actionStarted,
            userId: 'user-b',
            sessionId: 's9',
            timestamp: _t0.add(const Duration(seconds: 1)),
          ));

      expect(snapshot.sessionsByUser, hasLength(2));
    });
  });

  group('apply / 乱序与陈旧', () {
    test('ignores an event not newer than lastEventAt', () {
      final snapshot = _empty
          .apply(_event(type: RoomEventType.actionStarted))
          .apply(_event(
            type: RoomEventType.actionPaused,
            timestamp: _t0, // 同刻 → 忽略
          ));

      expect(snapshot.sessionsByUser['user-a']!.status,
          ActionSessionStatus.active);
    });

    test('ignores a stale started arriving after a newer session', () {
      final snapshot = _empty
          .apply(_event(
            type: RoomEventType.actionStarted,
            sessionId: 's2',
            timestamp: _t0.add(const Duration(seconds: 30)),
          ))
          .apply(_event(
            type: RoomEventType.actionStarted,
            sessionId: 's1',
            timestamp: _t0,
          ));

      expect(snapshot.sessionsByUser['user-a']!.sessionId, 's2');
    });

    test('ignores events for other rooms and unknown types', () {
      final other = _empty.apply(
        _event(type: RoomEventType.actionStarted, roomId: 'room-9'),
      );
      final unknown = _empty.apply(_event(type: 'member_joined'));

      expect(other.isEmpty, isTrue);
      expect(unknown.isEmpty, isTrue);
    });
  });

  group('apply / 状态迁移', () {
    test('pause freezes remaining, resume recomputes endsAt', () {
      final paused = _empty
          .apply(_event(type: RoomEventType.actionStarted))
          .apply(_event(
            type: RoomEventType.actionPaused,
            remainingSec: 0, // payload 未带 → 按事件时刻现算
            timestamp: _t0.add(const Duration(seconds: 120)),
          ));

      final pausedSession = paused.sessionsByUser['user-a']!;
      expect(pausedSession.status, ActionSessionStatus.paused);
      expect(pausedSession.pausedRemainingSec, 480);
      expect(pausedSession.endsAt, isNull);
      // 暂停期间剩余不随时间变化
      expect(
        pausedSession.remainingSecAt(_t0.add(const Duration(hours: 1))),
        480,
      );

      final resumedAt = _t0.add(const Duration(seconds: 300));
      final resumed = paused.apply(_event(
        type: RoomEventType.actionResumed,
        remainingSec: 0,
        timestamp: resumedAt,
      ));

      final resumedSession = resumed.sessionsByUser['user-a']!;
      expect(resumedSession.status, ActionSessionStatus.active);
      expect(resumedSession.endsAt, resumedAt.add(const Duration(seconds: 480)));
    });

    test('completed maps to idle immediately', () {
      final snapshot = _empty
          .apply(_event(type: RoomEventType.actionStarted))
          .apply(_event(
            type: RoomEventType.actionCompleted,
            timestamp: _t0.add(const Duration(seconds: 600)),
          ));

      final session = snapshot.sessionsByUser['user-a']!;
      expect(session.status, ActionSessionStatus.completed);
      expect(session.effectiveStateAt(_t0.add(const Duration(seconds: 601))),
          UserActivityState.idle);
    });
  });

  group('apply / 未知会话自举(中途进房/丢事件)', () {
    test('paused for an unknown session bootstraps from payload', () {
      final snapshot = _empty.apply(_event(
        type: RoomEventType.actionPaused,
        remainingSec: 240,
      ));

      final session = snapshot.sessionsByUser['user-a']!;
      expect(session.status, ActionSessionStatus.paused);
      expect(session.pausedRemainingSec, 240);
      expect(session.actionKey, 'strength_basic');
      expect(session.templateName, '深蹲');
    });

    test('resumed for an unknown session becomes active with payload remaining',
        () {
      final snapshot = _empty.apply(_event(
        type: RoomEventType.actionResumed,
        remainingSec: 180,
      ));

      final session = snapshot.sessionsByUser['user-a']!;
      expect(session.status, ActionSessionStatus.active);
      expect(session.endsAt, _t0.add(const Duration(seconds: 180)));
    });
  });

  group('过期与清扫', () {
    test('active session expires locally after endsAt (peer offline)', () {
      final snapshot = _empty.apply(_event(type: RoomEventType.actionStarted));
      final session = snapshot.sessionsByUser['user-a']!;
      final afterEnd = _t0.add(const Duration(seconds: 601));

      expect(session.isExpiredAt(afterEnd), isTrue);
      expect(session.effectiveStateAt(afterEnd), UserActivityState.idle);
      expect(session.remainingSecAt(afterEnd), 0);
    });

    test('sweep removes completed sessions after retention', () {
      final snapshot = _empty
          .apply(_event(type: RoomEventType.actionStarted))
          .apply(_event(
            type: RoomEventType.actionCompleted,
            timestamp: _t0.add(const Duration(seconds: 600)),
          ));

      final withinRetention = snapshot.sweep(
        _t0.add(const Duration(seconds: 602)),
      );
      expect(withinRetention.sessionsByUser, hasLength(1));

      final afterRetention = snapshot.sweep(
        _t0
            .add(const Duration(seconds: 600))
            .add(RoomActivitySnapshot.completedRetention)
            .add(const Duration(seconds: 1)),
      );
      expect(afterRetention.isEmpty, isTrue);
    });

    test('sweep removes long-expired active sessions and is identity-stable',
        () {
      final snapshot = _empty.apply(_event(type: RoomEventType.actionStarted));

      final untouched = snapshot.sweep(_t0.add(const Duration(seconds: 10)));
      expect(identical(untouched, snapshot), isTrue);

      final sweptAt = _t0
          .add(const Duration(seconds: 600))
          .add(RoomActivitySnapshot.expiredRetention)
          .add(const Duration(seconds: 1));
      expect(snapshot.sweep(sweptAt).isEmpty, isTrue);
    });
  });

  group('activityStatusOf', () {
    test('converts session to the presence-shaped snapshot', () {
      final snapshot = _empty.apply(_event(type: RoomEventType.actionStarted));
      final status = snapshot.activityStatusOf(
        'user-a',
        _t0.add(const Duration(seconds: 60)),
      )!;

      expect(status.activityState, UserActivityState.active);
      expect(status.remainingSec, 540);
      expect(status.templateName, '深蹲');
      expect(status.sessionId, 's1');
      expect(snapshot.activityStatusOf('nobody', _t0), isNull);
    });
  });
}

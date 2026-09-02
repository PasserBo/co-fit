import 'package:cofit/features/room/domain/entity/room_presence_member.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomPresenceMember.fromMap', () {
    test('reads nickname and activity from presence data', () {
      final member = RoomPresenceMember.fromMap({
        'clientId': 'cofit-u1',
        'userId': 'u1',
        'data': {
          'userId': 'u1',
          'nickname': '小李',
          'activity': {
            'activityState': 'active',
            'sessionId': 's1',
            'remainingSec': 30,
            'updatedAtEpochMs': 1700000000000,
          },
        },
      });

      expect(member.userId, 'u1');
      expect(member.nickname, '小李');
      expect(member.activityStatus.activityState, UserActivityState.active);
      expect(member.activityStatus.sessionId, 's1');
    });

    test('nickname missing or blank → null(展示层回退 uid 截断)', () {
      final noNickname = RoomPresenceMember.fromMap({
        'clientId': 'cofit-u1',
        'userId': 'u1',
        'data': {'userId': 'u1'},
      });
      final blankNickname = RoomPresenceMember.fromMap({
        'clientId': 'cofit-u1',
        'userId': 'u1',
        'data': {'userId': 'u1', 'nickname': '  '},
      });

      expect(noNickname.nickname, isNull);
      expect(blankNickname.nickname, isNull);
    });

    test('legacy payload without data map still parses', () {
      final member = RoomPresenceMember.fromMap({
        'clientId': 'cofit-u2',
        'userId': 'u2',
      });

      expect(member.userId, 'u2');
      expect(member.nickname, isNull);
      expect(member.activityStatus.activityState, UserActivityState.idle);
    });
  });
}

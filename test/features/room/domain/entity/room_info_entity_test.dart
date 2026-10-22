import 'package:cofit/features/room/domain/entity/room_info_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomInfoEntity.memberIds', () {
    test('derives from members map keys; owner always counts as member', () {
      final room = RoomInfoEntity.fromMap({
        'roomId': 'r1',
        'name': '晨练',
        'ownerId': 'owner',
        'members': {
          'owner': {'role': 'owner'},
          'alice': {'role': 'member'},
          ' ': {'role': 'member'},
        },
      });

      expect(room.memberIds, ['owner', 'alice']);
      expect(room.isMember('alice'), isTrue);
      expect(room.isMember('owner'), isTrue);
      expect(room.isMember('bob'), isFalse);
    });

    test('missing members map → empty list, owner still member', () {
      final room = RoomInfoEntity.fromMap({'roomId': 'r1', 'ownerId': 'o'});
      expect(room.memberIds, isEmpty);
      expect(room.isMember('o'), isTrue);
      expect(room.isMember('x'), isFalse);
    });

    test('toMap does not write memberIds back', () {
      final room = RoomInfoEntity.fromMap({
        'roomId': 'r1',
        'ownerId': 'o',
        'members': {'o': {}, 'a': {}},
      });
      expect(room.toMap().containsKey('memberIds'), isFalse);
      expect(room.toMap().containsKey('members'), isFalse);
    });
  });
}

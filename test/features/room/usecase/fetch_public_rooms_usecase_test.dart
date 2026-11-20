import 'package:cofit/features/room/domain/entity/room_info_entity.dart';
import 'package:cofit/features/room/usecase/fetch_public_rooms_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

RoomInfoEntity _room(
  String id, {
  String name = 'room',
  String description = '',
  String visibility = RoomVisibility.public,
  int members = 1,
  DateTime? createdAt,
}) {
  return RoomInfoEntity(
    roomId: id,
    name: name,
    description: description,
    visibility: visibility,
    ownerId: 'owner',
    shareLinkHash: 'h',
    shareSalt: 's',
    createdAt: createdAt,
    memberIds: [for (var i = 0; i < members; i++) 'u$i'],
  );
}

void main() {
  group('sortPublicRooms', () {
    test('members desc, then newer first (spec: 公开房间列表内容与顺序)', () {
      final a = _room('A', members: 5, createdAt: DateTime(2026, 1, 1));
      final b = _room('B', members: 2, createdAt: DateTime(2026, 1, 1));
      final c = _room('C', members: 2, createdAt: DateTime(2026, 2, 1));
      expect(sortPublicRooms([b, a, c]).map((r) => r.roomId), ['A', 'C', 'B']);
    });

    test('rooms without createdAt go last among equal member counts', () {
      final a = _room('A', members: 1);
      final b = _room('B', members: 1, createdAt: DateTime(2026, 1, 1));
      expect(sortPublicRooms([a, b]).map((r) => r.roomId), ['B', 'A']);
    });

    test('drops unlisted rooms and rooms without a name', () {
      final rooms = [
        _room('A', visibility: RoomVisibility.unlisted),
        _room('B', name: '  '),
        _room('C'),
      ];
      expect(sortPublicRooms(rooms).map((r) => r.roomId), ['C']);
    });
  });

  group('filterRoomsByQuery', () {
    final rooms = [
      _room('1', name: '晨练小队'),
      _room('2', name: '夜跑俱乐部', description: 'Run at NIGHT'),
    ];

    test('matches name', () {
      expect(filterRoomsByQuery(rooms, '晨练').map((r) => r.roomId), ['1']);
    });

    test('matches description case-insensitively, trims query', () {
      expect(filterRoomsByQuery(rooms, '  night ').map((r) => r.roomId), [
        '2',
      ]);
    });

    test('empty query returns all, no match returns empty', () {
      expect(filterRoomsByQuery(rooms, '   '), rooms);
      expect(filterRoomsByQuery(rooms, '游泳'), isEmpty);
    });
  });
}

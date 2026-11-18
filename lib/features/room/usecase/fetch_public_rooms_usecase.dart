import '../data/firebase_room_repository.dart';
import '../domain/entity/room_info_entity.dart';

/// 发现房间:取公开房间并按「成员数多→少,同人数新建在前」排序
/// (2026-11-19 决议,见 docs/spec/changes/add-room-create-and-discovery)。
class FetchPublicRoomsUsecase {
  FetchPublicRoomsUsecase(this._repository);

  /// 冷启动期一次取回的上限;超过后改服务端分页 + 搜索(proposal Open questions)。
  static const int fetchLimit = 100;

  final FirebaseRoomRepository _repository;

  Future<List<RoomInfoEntity>> execute() async {
    final rooms = await _repository.fetchPublicRooms(limit: fetchLimit);
    return sortPublicRooms(rooms);
  }
}

/// 只保留公开且有房名的房间,按成员数降序、创建时间降序(无时间的排最后)。
List<RoomInfoEntity> sortPublicRooms(Iterable<RoomInfoEntity> rooms) {
  final list = [
    for (final room in rooms)
      if (room.visibility == RoomVisibility.public &&
          room.name.trim().isNotEmpty)
        room,
  ];
  list.sort((a, b) {
    final byMembers = b.memberIds.length.compareTo(a.memberIds.length);
    if (byMembers != 0) {
      return byMembers;
    }
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime == null) {
      return 0;
    }
    if (aTime == null) {
      return 1;
    }
    if (bTime == null) {
      return -1;
    }
    return bTime.compareTo(aTime);
  });
  return list;
}

/// 搜索:房名或简介包含关键词(忽略首尾空白、不区分英文大小写);空关键词返回全部。
List<RoomInfoEntity> filterRoomsByQuery(
  List<RoomInfoEntity> rooms,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return rooms;
  }
  return [
    for (final room in rooms)
      if (room.name.toLowerCase().contains(needle) ||
          room.description.toLowerCase().contains(needle))
        room,
  ];
}

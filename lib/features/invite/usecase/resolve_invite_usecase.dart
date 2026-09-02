import '../../room/data/firebase_room_repository.dart';
import '../../room/domain/entity/room_info_entity.dart';
import '../domain/entity/invite_link_entity.dart';

/// 邀请链接无效(房间不存在 / hash 不匹配)。
class InviteInvalidException implements Exception {
  const InviteInvalidException(this.reason);

  final String reason;

  @override
  String toString() => 'InviteInvalidException: $reason';
}

class ResolveInviteResult {
  const ResolveInviteResult({
    required this.room,
    required this.alreadyJoined,
  });

  final RoomInfoEntity room;
  final bool alreadyJoined;
}

class ResolveInviteUsecase {
  ResolveInviteUsecase(this._roomRepository);

  final FirebaseRoomRepository _roomRepository;

  Future<ResolveInviteResult> execute({
    required InviteLinkEntity link,
    required List<String> joinedRoomIds,
  }) async {
    final room = await _roomRepository.fetchRoomInfo(roomId: link.roomId);
    if (room == null) {
      throw const InviteInvalidException('房间不存在或已解散');
    }
    if (room.shareLinkHash != link.hash) {
      throw const InviteInvalidException('邀请链接无效或已过期');
    }
    return ResolveInviteResult(
      room: room,
      alreadyJoined: joinedRoomIds.contains(room.roomId),
    );
  }
}

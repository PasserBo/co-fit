import '../../room/domain/entity/room_info_entity.dart';
import '../domain/invite_link_format.dart';

class BuildInviteLinkUsecase {
  Uri execute({required RoomInfoEntity room}) {
    return InviteLinkFormat.build(
      roomId: room.roomId,
      hash: room.shareLinkHash,
    );
  }
}

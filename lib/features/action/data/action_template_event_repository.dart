import '../../room/domain/entity/room_event.dart';

abstract class ActionTemplateEventRepository {
  Future<void> publishRoomEvent({
    required RoomEvent event,
  });
}

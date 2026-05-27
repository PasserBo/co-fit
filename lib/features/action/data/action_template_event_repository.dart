import '../../room/data/room_event.dart';

abstract class ActionTemplateEventRepository {
  Future<void> publishRoomEvent({
    required RoomEvent event,
  });
}

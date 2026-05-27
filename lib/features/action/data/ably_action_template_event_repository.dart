import '../../room/data/room_event.dart';
import 'action_template_event_repository.dart';

class AblyActionTemplateEventRepository implements ActionTemplateEventRepository {
  AblyActionTemplateEventRepository({
    required Future<void> Function(RoomEvent event) publishEvent,
  }) : _publishEvent = publishEvent;

  final Future<void> Function(RoomEvent event) _publishEvent;

  @override
  Future<void> publishRoomEvent({
    required RoomEvent event,
  }) {
    return _publishEvent(event);
  }
}

import '../data/room_event.dart';
import '../data/room_realtime_repository.dart';

class PublishRoomEventUsecase {
  PublishRoomEventUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Future<void> execute({
    required RoomEvent event,
  }) {
    return _repository.publishEvent(event: event);
  }
}

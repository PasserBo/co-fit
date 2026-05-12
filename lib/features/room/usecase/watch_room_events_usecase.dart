import '../data/room_event.dart';
import '../data/room_realtime_repository.dart';

class WatchRoomEventsUsecase {
  WatchRoomEventsUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Stream<RoomEvent> execute({
    required String roomId,
  }) {
    return _repository.watchRoomEvents(roomId: roomId);
  }
}

import '../data/room_presence_member.dart';
import '../data/room_realtime_repository.dart';

class WatchRoomPresenceUsecase {
  WatchRoomPresenceUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Stream<List<RoomPresenceMember>> execute({
    required String roomId,
  }) {
    return _repository.watchPresence(roomId: roomId);
  }
}

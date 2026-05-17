import '../data/room_realtime_repository.dart';

class JoinRoomUsecase {
  JoinRoomUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Future<void> execute({
    required String roomId,
    required String userId,
  }) {
    return _repository.subscribeRoom(roomId: roomId, userId: userId);
  }
}

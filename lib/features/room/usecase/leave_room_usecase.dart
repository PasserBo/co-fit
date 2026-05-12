import '../data/room_realtime_repository.dart';

class LeaveRoomUsecase {
  LeaveRoomUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Future<void> execute({
    required String roomId,
  }) {
    return _repository.leaveRoom(roomId: roomId);
  }
}

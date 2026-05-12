import '../data/room_realtime_repository.dart';

class DisconnectRealtimeUsecase {
  DisconnectRealtimeUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Future<void> execute() {
    return _repository.disconnect();
  }
}

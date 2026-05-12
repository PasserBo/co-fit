import '../data/room_realtime_repository.dart';

class ConnectRealtimeUsecase {
  ConnectRealtimeUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Future<void> execute() {
    return _repository.connect();
  }
}

import '../data/room_realtime_repository.dart';

class WatchConnectionStateUsecase {
  WatchConnectionStateUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Stream<String> execute() {
    return _repository.watchConnectionState();
  }
}

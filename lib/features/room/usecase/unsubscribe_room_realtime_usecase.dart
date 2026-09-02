import '../data/room_realtime_repository.dart';

/// 离开房间的 Ably 实时频道(presence leave)。
/// Firestore 侧的退出房间见 leave_room_usecase.dart。
class UnsubscribeRoomRealtimeUsecase {
  UnsubscribeRoomRealtimeUsecase(this._repository);

  final RoomRealtimeRepository _repository;

  Future<void> execute({
    required String roomId,
  }) {
    return _repository.leaveRoom(roomId: roomId);
  }
}

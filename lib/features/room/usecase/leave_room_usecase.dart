import '../data/firebase_room_repository.dart';

/// 退出房间(Firestore 成员关系)。实时频道退出见
/// unsubscribe_room_realtime_usecase.dart,两步由调用方编排。
class LeaveRoomUsecase {
  LeaveRoomUsecase(this._repository);

  final FirebaseRoomRepository _repository;

  Future<void> execute({
    required String roomId,
    required String userId,
  }) {
    return _repository.leaveRoom(roomId: roomId, userId: userId);
  }
}

import '../data/firebase_room_repository.dart';

/// 房主解散房间(Firestore 侧)。调用方编排后续:
/// Ably unsubscribe + refreshJoinedRooms(同退出房间流程)。
/// 成员侧靠懒清理感知房间已解散(见 FirebaseRoomRepository.dissolveRoom 注释)。
class DissolveRoomUsecase {
  DissolveRoomUsecase(this._repository);

  final FirebaseRoomRepository _repository;

  Future<void> execute({
    required String roomId,
    required String ownerId,
  }) {
    return _repository.dissolveRoom(roomId: roomId, ownerId: ownerId);
  }
}

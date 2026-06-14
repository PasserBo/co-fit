import '../data/firebase_room_repository.dart';

class JoinRoomUsecase {
  JoinRoomUsecase(this._repository);

  final FirebaseRoomRepository _repository;

  Future<void> execute({
    required String roomId,
    required String userId,
  }) {
    return _repository.joinRoom(roomId: roomId, userId: userId);
  }
}

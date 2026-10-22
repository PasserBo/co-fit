import '../data/firebase_room_repository.dart';

/// 房主移出成员(UGC 合规:房主需能移除骚扰者)。
/// owner 校验在 rules 层;UI 只对 owner 露出入口,且不能移出自己。
class RemoveRoomMemberUsecase {
  RemoveRoomMemberUsecase(this._repository);

  final FirebaseRoomRepository _repository;

  Future<void> execute({
    required String roomId,
    required String ownerId,
    required String memberUserId,
  }) {
    if (memberUserId.trim() == ownerId.trim()) {
      throw ArgumentError.value(
        memberUserId,
        'memberUserId',
        'Owner cannot remove themselves; dissolve the room instead.',
      );
    }
    return _repository.removeMember(
      roomId: roomId,
      ownerId: ownerId,
      memberUserId: memberUserId,
    );
  }
}

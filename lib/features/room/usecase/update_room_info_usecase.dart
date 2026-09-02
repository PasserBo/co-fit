import '../data/firebase_room_repository.dart';
import '../domain/entity/room_info_entity.dart';

/// 房主更新房间信息。owner 校验在 rules 层(非 owner 会被拒),
/// UI 层同时只对 owner 露出入口。
class UpdateRoomInfoUsecase {
  UpdateRoomInfoUsecase(this._repository);

  final FirebaseRoomRepository _repository;

  Future<void> execute({
    required String roomId,
    required String name,
    required String description,
    required String visibility,
  }) {
    final trimmedName = name.trim();
    final normalizedVisibility = visibility.trim().toLowerCase();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Room name must not be empty.');
    }
    if (!RoomVisibility.allowed.contains(normalizedVisibility)) {
      throw ArgumentError.value(
        visibility,
        'visibility',
        'Visibility must be one of: ${RoomVisibility.allowed.join(', ')}.',
      );
    }
    return _repository.updateRoomInfo(
      roomId: roomId,
      name: trimmedName,
      description: description.trim(),
      visibility: normalizedVisibility,
    );
  }
}

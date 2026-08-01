import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository_provider.dart';
import '../domain/entity/room_info_entity.dart';

/// 按 roomId 读房间信息(名称等)。房间不存在时为 null。
final roomInfoProvider = FutureProvider.family<RoomInfoEntity?, String>((
  ref,
  roomId,
) {
  return ref
      .watch(firebaseRoomRepositoryProvider)
      .fetchRoomInfo(roomId: roomId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository_provider.dart';
import '../domain/entity/room_info_entity.dart';

/// 按 roomId 实时订阅房间信息(Firestore 快照流)。
/// 房间不存在 / 被解散时为 null;成员变更(移出)即时下发,
/// 所以房主的成员列表、被移出者的懒清理都不再依赖重启或手动刷新。
final roomInfoProvider = StreamProvider.family<RoomInfoEntity?, String>((
  ref,
  roomId,
) {
  return ref
      .watch(firebaseRoomRepositoryProvider)
      .watchRoomInfo(roomId: roomId);
});

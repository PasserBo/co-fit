import '../../auth/domain/repository/auth_repository.dart';
import '../../room/data/firebase_room_repository.dart';
import '../data/firebase_user_data_eraser.dart';

/// 删除账号(Apple 上架强制要求「支持账号删除」)。
///
/// 顺序很关键 —— Firestore 的清理必须在注销 Auth 用户**之前**完成,
/// 否则 uid 失效后 rules 会拒绝所有写入,数据将永久残留:
///   1. 重认证(Firebase 要求近期登录;Apple 账号顺带取回新鲜授权码)
///   2. 房间:自己建的解散,别人的退出
///   3. users/{uid} 及全部子集合清空
///   4. 撤销 Apple token + 删除 Auth 用户
class DeleteAccountUsecase {
  DeleteAccountUsecase({
    required AuthRepository authRepository,
    required FirebaseRoomRepository roomRepository,
    required FirebaseUserDataEraser userDataEraser,
  })  : _authRepository = authRepository,
        _roomRepository = roomRepository,
        _userDataEraser = userDataEraser;

  final AuthRepository _authRepository;
  final FirebaseRoomRepository _roomRepository;
  final FirebaseUserDataEraser _userDataEraser;

  Future<void> execute({required String userId}) async {
    final appleAuthorizationCode = await _authRepository.reauthenticate();

    await _cleanUpRooms(userId);
    await _userDataEraser.eraseUserData(userId: userId);

    await _authRepository.deleteAccount(
      appleAuthorizationCode: appleAuthorizationCode,
    );
  }

  /// 逐个房间:房主 → 解散(无移交功能);成员 → 退出。
  /// 单个房间失败不阻断整体流程,否则用户会卡在「删不掉账号」的死局里。
  Future<void> _cleanUpRooms(String userId) async {
    final roomIds = await _roomRepository.fetchJoinedRoomIds(userId: userId);
    for (final roomId in roomIds) {
      try {
        final room = await _roomRepository.fetchRoomInfo(roomId: roomId);
        if (room == null) {
          // 房间已解散,只剩残留 membership —— 由 eraseUserData 一并清掉。
          continue;
        }
        if (room.ownerId == userId) {
          await _roomRepository.dissolveRoom(roomId: roomId, ownerId: userId);
        } else {
          await _roomRepository.leaveRoom(roomId: roomId, userId: userId);
        }
      } catch (_) {
        // 继续处理其余房间。
      }
    }
  }
}

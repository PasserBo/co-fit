import '../domain/entity/push_permission_status.dart';
import '../domain/push_messaging_gateway.dart';
import 'sync_push_device_usecase.dart';

/// 首次请求通知权限的时机(spec: 首次请求通知权限):
/// 还没问过,且刚完成的这张卡所在房间里还有其他成员。
/// 「每台设备只主动请求一次」由系统保证:问过之后状态不再是 notDetermined。
bool shouldAskPushPermission({
  required PushPermissionStatus status,
  required int otherMemberCount,
}) {
  return status == PushPermissionStatus.notDetermined && otherMemberCount > 0;
}

/// 完成一张卡后按需请求权限;允许后立刻登记设备。
class AskPushPermissionAfterWorkoutUsecase {
  AskPushPermissionAfterWorkoutUsecase(this._gateway, this._sync);

  final PushMessagingGateway _gateway;
  final SyncPushDeviceUsecase _sync;

  /// 返回是否弹出了请求。
  Future<bool> execute({
    required String userId,
    required int otherMemberCount,
  }) async {
    final status = await _gateway.permissionStatus();
    if (!shouldAskPushPermission(
      status: status,
      otherMemberCount: otherMemberCount,
    )) {
      return false;
    }
    final result = await _gateway.requestPermission();
    if (result.canReceive) {
      await _sync.execute(userId: userId);
    }
    return true;
  }
}

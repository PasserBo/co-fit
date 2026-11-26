import '../domain/entity/push_permission_status.dart';
import '../domain/push_device_repository.dart';
import '../domain/push_messaging_gateway.dart';

/// 让服务端的设备登记与系统权限一致:允许 → 登记当前 token;
/// 拒绝 → 撤掉登记(否则服务端会为看不到的推送消耗冷却)。
/// 时机:进入 App(bootstrap 后)、回到前台、授权后、token 刷新。
/// 每次都带上设备当地时差:换时区 / 夏令时切换后回到前台即更新(夜间不推送用)。
class SyncPushDeviceUsecase {
  SyncPushDeviceUsecase(
    this._gateway,
    this._devices, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PushMessagingGateway _gateway;
  final PushDeviceRepository _devices;
  final DateTime Function() _now;

  /// 返回登记后的权限状态。
  Future<PushPermissionStatus> execute({
    required String userId,
    String? token,
  }) async {
    final status = await _gateway.permissionStatus();
    // 没问过权限:从未登记过,什么都不用做。
    if (status == PushPermissionStatus.notDetermined) {
      return status;
    }
    final current = token ?? await _gateway.token();
    if (current == null || current.isEmpty) {
      return status;
    }
    if (status.canReceive) {
      await _devices.register(
        userId: userId,
        token: current,
        utcOffsetMinutes: _now().timeZoneOffset.inMinutes,
      );
    } else {
      await _devices.unregister(userId: userId, token: current);
    }
    return status;
  }
}

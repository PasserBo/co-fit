import '../domain/entity/push_permission_status.dart';
import '../domain/notification_settings_repository.dart';
import '../domain/push_messaging_gateway.dart';
import 'sync_push_device_usecase.dart';

/// 「我的」里的总开关。打开时若还没问过系统权限,顺带请求(spec: 推送总开关)。
class SetPartnerStartPushUsecase {
  SetPartnerStartPushUsecase(this._settings, this._gateway, this._sync);

  final NotificationSettingsRepository _settings;
  final PushMessagingGateway _gateway;
  final SyncPushDeviceUsecase _sync;

  /// 返回之后的系统权限状态(界面据此显示「去系统设置」说明)。
  Future<PushPermissionStatus> execute({
    required String userId,
    required bool enabled,
  }) async {
    await _settings.setPartnerStartEnabled(userId: userId, enabled: enabled);
    var status = await _gateway.permissionStatus();
    if (enabled && status == PushPermissionStatus.notDetermined) {
      status = await _gateway.requestPermission();
      if (status.canReceive) {
        await _sync.execute(userId: userId);
      }
    }
    return status;
  }
}

/// 房间菜单里的静音 / 取消静音。
class SetRoomPushMutedUsecase {
  SetRoomPushMutedUsecase(this._settings);

  final NotificationSettingsRepository _settings;

  Future<void> execute({
    required String userId,
    required String roomId,
    required bool muted,
  }) {
    final room = roomId.trim();
    if (room.isEmpty) {
      throw ArgumentError.value(roomId, 'roomId', 'must not be empty');
    }
    return _settings.setRoomMuted(userId: userId, roomId: room, muted: muted);
  }
}

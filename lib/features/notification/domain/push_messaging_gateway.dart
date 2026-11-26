import 'entity/push_message.dart';
import 'entity/push_permission_status.dart';

/// 系统推送能力(权限、设备 token、点开的推送)。
abstract interface class PushMessagingGateway {
  Future<PushPermissionStatus> permissionStatus();

  /// 弹系统权限请求(iOS 只在 notDetermined 时真正弹出)。
  Future<PushPermissionStatus> requestPermission();

  /// 当前设备 token;系统还没准备好时为 null。
  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// 作废本设备 token(退出登录:旧 token 之后发不到这台设备)。
  Future<void> deleteToken();

  /// 冷启动时点开的推送。
  Future<PushMessage?> initialMessage();

  /// 后台时点开的推送。
  Stream<PushMessage> get openedMessages;
}

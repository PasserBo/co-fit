/// 系统通知权限。
enum PushPermissionStatus {
  /// 还没问过(iOS 只能弹一次系统请求)。
  notDetermined,

  /// 允许(含临时授权)。
  authorized,

  /// 拒绝:只能让用户去系统设置里打开。
  denied;

  bool get canReceive => this == authorized;
}

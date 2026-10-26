/// 远程功能开关(Firebase Remote Config)。
/// 字段默认值 = 远端未配置时的行为;新开关先在这里加字段与默认值,
/// 再到 Firebase console 建同名参数。
class FeatureFlags {
  const FeatureFlags({this.authGoogleEnabled = false});

  /// 登录页是否展示「通过 Google 登录」(2026-10-26 决议:默认关,
  /// Apple/Google uid 不互通问题解决前不开放)。参数名 `auth_google_enabled`。
  final bool authGoogleEnabled;

  static const defaults = FeatureFlags();

  static const keyAuthGoogleEnabled = 'auth_google_enabled';

  /// 与 Remote Config 的 `setDefaults` 形状一致。
  static Map<String, Object> defaultsMap() => {
    keyAuthGoogleEnabled: defaults.authGoogleEnabled,
  };

  factory FeatureFlags.fromReader(bool Function(String key) readBool) {
    return FeatureFlags(authGoogleEnabled: readBool(keyAuthGoogleEnabled));
  }
}

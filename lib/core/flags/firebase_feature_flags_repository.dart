import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'feature_flags.dart';
import 'feature_flags_repository.dart';

/// Remote Config 实现:登录前即可拉取(不需要 Auth)。
/// debug 下 fetch 间隔为 0 便于调试;release 下 1 小时(Remote Config 配额友好)。
class FirebaseFeatureFlagsRepository implements FeatureFlagsRepository {
  FirebaseFeatureFlagsRepository({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<FeatureFlags> load() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(FeatureFlags.defaultsMap());
      await _remoteConfig.fetchAndActivate();
    } catch (error) {
      // 离线 / 配额 / 首次无模板:沿用默认值或上次激活值
      debugPrint('RemoteConfig fetch failed, using defaults: $error');
    }
    return FeatureFlags.fromReader(_remoteConfig.getBool);
  }
}

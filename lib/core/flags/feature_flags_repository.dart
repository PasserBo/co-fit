import 'feature_flags.dart';

abstract class FeatureFlagsRepository {
  /// 拉取并激活最新开关;任何失败都应回退到 [FeatureFlags.defaults] 或上次激活值,
  /// 不得抛出到 UI。
  Future<FeatureFlags> load();
}

class InMemoryFeatureFlagsRepository implements FeatureFlagsRepository {
  InMemoryFeatureFlagsRepository([this.flags = FeatureFlags.defaults]);

  final FeatureFlags flags;

  @override
  Future<FeatureFlags> load() async => flags;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feature_flags.dart';
import 'feature_flags_repository.dart';
import 'firebase_feature_flags_repository.dart';

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return FirebaseFeatureFlagsRepository();
});

/// 启动时拉一次;加载中/失败一律按 [FeatureFlags.defaults](开关默认关)。
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) {
  return ref.watch(featureFlagsRepositoryProvider).load();
});

/// 同步读法:UI 直接 watch 这个,永远有值。
final featureFlagsValueProvider = Provider<FeatureFlags>((ref) {
  return ref.watch(featureFlagsProvider).value ?? FeatureFlags.defaults;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_welcome_tour_seen_repository.dart';
import '../domain/welcome_tour_seen_repository.dart';

final welcomeTourSeenRepositoryProvider = Provider<WelcomeTourSeenRepository>((
  ref,
) {
  return SharedPreferencesWelcomeTourSeenRepository();
});

/// 「演示已看过」的内存态 + 持久化。
///
/// AuthGate 在未登录分支 watch 它:loading → splash(防闪登录页),
/// false → 演示房间,true → 登录页。[markSeen] 先把内存态置 true 再落盘,
/// 让门控立刻切页;落盘失败只会让下次启动再看一遍演示,不值得打断用户,
/// 所以吞掉异常。
class WelcomeTourSeenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(welcomeTourSeenRepositoryProvider).isSeen();
  }

  Future<void> markSeen() async {
    state = const AsyncData(true);
    try {
      await ref.read(welcomeTourSeenRepositoryProvider).markSeen();
    } catch (_) {
      // 见类注释:持久化失败不回滚内存态。
    }
  }
}

final welcomeTourSeenProvider =
    AsyncNotifierProvider<WelcomeTourSeenNotifier, bool>(
      WelcomeTourSeenNotifier.new,
    );

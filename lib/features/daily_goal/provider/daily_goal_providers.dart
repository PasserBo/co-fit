import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/flags/feature_flags_provider.dart';
import '../../action/provider/action_session_history_providers.dart';
import '../../auth/provider/auth_state_provider.dart';
import '../data/shared_preferences_daily_goal_repository.dart';
import '../domain/daily_goal_repository.dart';
import '../domain/daily_progress_metric.dart';
import '../domain/entity/daily_goal_config.dart';
import '../domain/entity/daily_progress.dart';
import '../usecase/compute_daily_progress.dart';

/// 今日进度的内容配置:远程值解析后的结果,读不到时是内置默认值。
final dailyGoalConfigProvider = Provider<DailyGoalConfig>((ref) {
  return DailyGoalConfig.parse(
    ref.watch(featureFlagsValueProvider).dailyGoalConfig,
  );
});

/// 当前的计量方式。换计量方式 = 改配置,或覆盖这个 provider。
final dailyProgressMetricProvider = Provider<DailyProgressMetric>((ref) {
  final config = ref.watch(dailyGoalConfigProvider);
  return dailyProgressMetricRegistry[config.metric] ?? const CardCountMetric();
});

final dailyGoalRepositoryProvider = Provider<DailyGoalRepository>((ref) {
  return SharedPreferencesDailyGoalRepository();
});

/// 目标按哪个用户保存;未登录为 null。
final dailyGoalUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// 现在几点(测试里覆盖)。
final dailyGoalClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

/// 「今天」是哪个本地日历日。在下一个零点由定时器更新;定时器在后台不可靠,
/// 所以回到前台时也重新核对(design.md §3)。
class CurrentDayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    final lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _timer?.cancel();
      lifecycle.dispose();
    });
    final today = localDayOf(ref.watch(dailyGoalClockProvider)());
    _scheduleNextMidnight(today);
    return today;
  }

  /// 重新核对今天是哪一天;变了才通知。
  void refresh() {
    final today = localDayOf(ref.read(dailyGoalClockProvider)());
    if (today != state) {
      state = today;
    }
    _scheduleNextMidnight(today);
  }

  void _scheduleNextMidnight(DateTime today) {
    _timer?.cancel();
    final now = ref.read(dailyGoalClockProvider)();
    final nextMidnight = DateTime(today.year, today.month, today.day + 1);
    final wait = nextMidnight.difference(now);
    _timer = Timer(wait.isNegative ? Duration.zero : wait, refresh);
  }
}

final currentDayProvider = NotifierProvider<CurrentDayNotifier, DateTime>(
  CurrentDayNotifier.new,
);

/// 用户在本机选的今日目标;没选过为 null。
class SavedDailyTargetNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final userId = ref.watch(dailyGoalUserIdProvider);
    if (userId == null) {
      return null;
    }
    return ref
        .watch(dailyGoalRepositoryProvider)
        .loadTarget(
          userId: userId,
          metricId: ref.watch(dailyProgressMetricProvider).id,
        );
  }

  /// 改目标:立即生效,之后每天沿用。
  Future<void> setTarget(int target) async {
    final userId = ref.read(dailyGoalUserIdProvider);
    if (userId == null || target < 1) {
      return;
    }
    state = AsyncData(target);
    await ref
        .read(dailyGoalRepositoryProvider)
        .saveTarget(
          userId: userId,
          metricId: ref.read(dailyProgressMetricProvider).id,
          target: target,
        );
  }
}

final savedDailyTargetProvider =
    AsyncNotifierProvider<SavedDailyTargetNotifier, int?>(
      SavedDailyTargetNotifier.new,
    );

/// 今日目标:用户选过用选的,否则用配置的默认值。
final dailyTargetProvider = Provider<int>((ref) {
  return ref.watch(savedDailyTargetProvider).value ??
      ref.watch(dailyGoalConfigProvider).defaultTarget;
});

/// 选择面板里的可选目标:配置的清单,加上用户当前的目标(清单后来改了也不丢)。
final dailyTargetChoicesProvider = Provider<List<int>>((ref) {
  return {
    ...ref.watch(dailyGoalConfigProvider).choices,
    ref.watch(dailyTargetProvider),
  }.toList()..sort();
});

/// 今日进度。运动记录加载中 / 失败时跟随其状态。
final dailyProgressProvider = Provider<AsyncValue<DailyProgress>>((ref) {
  final day = ref.watch(currentDayProvider);
  final metric = ref.watch(dailyProgressMetricProvider);
  final target = ref.watch(dailyTargetProvider);
  return ref
      .watch(recentSessionsProvider)
      .whenData(
        (records) => computeDailyProgress(
          records: records,
          day: day,
          metric: metric,
          target: target,
        ),
      );
});

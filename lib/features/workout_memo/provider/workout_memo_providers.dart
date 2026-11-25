import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/flags/feature_flags_provider.dart';
import '../../action/domain/entity/action_session_record.dart';
import '../../action/provider/action_session_history_providers.dart';
import '../../auth/provider/auth_state_provider.dart';
import '../data/firebase_workout_memo_repository.dart';
import '../domain/entity/workout_memo.dart';
import '../domain/entity/workout_memo_config.dart';
import '../domain/workout_memo_repository.dart';
import '../usecase/memo_prompt.dart';
import '../usecase/save_workout_memo_usecase.dart';

/// 运动 memo 的内容配置:远程值解析后的结果,读不到时是内置默认值。
final workoutMemoConfigProvider = Provider<WorkoutMemoConfig>((ref) {
  return WorkoutMemoConfig.parse(
    ref.watch(featureFlagsValueProvider).workoutMemoConfig,
  );
});

final workoutMemoRepositoryProvider = Provider<WorkoutMemoRepository>((ref) {
  return FirebaseWorkoutMemoRepository();
});

final saveWorkoutMemoUsecaseProvider = Provider<SaveWorkoutMemoUsecase>((ref) {
  return SaveWorkoutMemoUsecase(ref.watch(workoutMemoRepositoryProvider));
});

/// memo 属于哪个用户;未登录为 null。
final workoutMemoUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// 现在几点(测试里覆盖)。
final workoutMemoClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

/// 最近的 memo,按运动记录的 id 索引。改动先落在这里(立即显示)再写云端;
/// 写失败回滚并把错误抛给调用方(design.md §5)。
class WorkoutMemosNotifier extends AsyncNotifier<Map<String, WorkoutMemo>> {
  @override
  Future<Map<String, WorkoutMemo>> build() async {
    final userId = ref.watch(workoutMemoUserIdProvider);
    if (userId == null) {
      return const {};
    }
    final memos = await ref
        .watch(workoutMemoRepositoryProvider)
        .fetchRecent(userId: userId);
    return {for (final memo in memos) memo.sessionId: memo};
  }

  /// 把 [record] 的 memo 改成 [feel] / [note](整份替换;全空 = 删除)。
  /// 保存失败时回滚并重新抛出。
  Future<void> put(
    ActionSessionRecord record, {
    required String? feel,
    required String? note,
  }) async {
    final userId = ref.read(workoutMemoUserIdProvider);
    if (userId == null) {
      return;
    }
    final text = note?.trim();
    final memo = WorkoutMemo(
      sessionId: record.sessionId,
      templateId: record.templateId,
      completedAt: record.completedAt,
      updatedAt: ref.read(workoutMemoClockProvider)(),
      feel: feel,
      note: text == null || text.isEmpty ? null : text,
    );
    // 加载失败时也允许写:从空表开始
    final before = state.value ?? const <String, WorkoutMemo>{};
    final after = {...before};
    if (memo.isEmpty) {
      after.remove(memo.sessionId);
    } else {
      after[memo.sessionId] = memo;
    }
    state = AsyncData(after);
    try {
      await ref
          .read(saveWorkoutMemoUsecaseProvider)
          .execute(userId: userId, memo: memo);
    } catch (_) {
      // 只回滚这一条,不覆盖期间别的改动
      final current = {...state.value ?? const <String, WorkoutMemo>{}};
      final previous = before[memo.sessionId];
      if (previous == null) {
        current.remove(memo.sessionId);
      } else {
        current[memo.sessionId] = previous;
      }
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> remove(ActionSessionRecord record) =>
      put(record, feel: null, note: null);
}

final workoutMemosProvider =
    AsyncNotifierProvider<WorkoutMemosNotifier, Map<String, WorkoutMemo>>(
      WorkoutMemosNotifier.new,
    );

/// 同步读法:加载中 / 失败时是空表(记录照常显示,只是不带 memo)。
final workoutMemoMapProvider = Provider<Map<String, WorkoutMemo>>((ref) {
  return ref.watch(workoutMemosProvider).value ?? const {};
});

/// 今日面板「刚才这张」针对的记录;没有为 null。到期时自己重算,
/// 回到前台时也重算(定时器在后台不可靠)。
final memoPromptTargetProvider = Provider<ActionSessionRecord?>((ref) {
  final records =
      ref.watch(recentSessionsProvider).value ?? const <ActionSessionRecord>[];
  final window = ref.watch(workoutMemoConfigProvider).promptWindow;
  final now = ref.watch(workoutMemoClockProvider)();
  final target = memoPromptTarget(records: records, now: now, window: window);
  if (target != null) {
    final remaining = target.completedAt.add(window).difference(now);
    final timer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      ref.invalidateSelf,
    );
    final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
  }
  return target;
});

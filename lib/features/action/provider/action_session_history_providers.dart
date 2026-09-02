import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_state_provider.dart';
import '../data/firebase_action_session_history_repository.dart';
import '../domain/action_session_history_repository.dart';
import '../domain/entity/action_session_record.dart';
import '../usecase/record_completed_session_usecase.dart';

final actionSessionHistoryRepositoryProvider =
    Provider<ActionSessionHistoryRepository>((ref) {
  return FirebaseActionSessionHistoryRepository();
});

final recordCompletedSessionUsecaseProvider =
    Provider<RecordCompletedSessionUsecase>((ref) {
  return RecordCompletedSessionUsecase(
    ref.watch(actionSessionHistoryRepositoryProvider),
  );
});

/// 最近运动记录(我的页统计用;完成一次会话后 invalidate 刷新)。
final recentSessionsProvider =
    FutureProvider<List<ActionSessionRecord>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const [];
  }
  return ref
      .watch(actionSessionHistoryRepositoryProvider)
      .fetchRecentSessions(userId: user.uid);
});

/// 客户端聚合的运动总计(基于最近 N 条,量大后再考虑 counters 文档)。
class SessionTotals {
  const SessionTotals({required this.count, required this.totalDurationSec});

  final int count;
  final int totalDurationSec;
}

final sessionTotalsProvider = Provider<SessionTotals>((ref) {
  final records =
      ref.watch(recentSessionsProvider).value ?? const <ActionSessionRecord>[];
  var totalSec = 0;
  for (final record in records) {
    totalSec += record.durationSec;
  }
  return SessionTotals(count: records.length, totalDurationSec: totalSec);
});

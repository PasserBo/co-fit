import '../domain/entity/workout_memo.dart';
import '../domain/workout_memo_repository.dart';

/// 测试用。[failWrites] 为 true 时保存与删除都抛出。
class InMemoryWorkoutMemoRepository implements WorkoutMemoRepository {
  final Map<String, Map<String, WorkoutMemo>> _byUser = {};
  bool failWrites = false;
  bool failReads = false;

  Map<String, WorkoutMemo> of(String userId) =>
      _byUser.putIfAbsent(userId, () => {});

  @override
  Future<List<WorkoutMemo>> fetchRecent({
    required String userId,
    int limit = 100,
  }) async {
    if (failReads) {
      throw StateError('read failed');
    }
    final memos = of(userId).values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return memos.take(limit).toList();
  }

  @override
  Future<void> save({required String userId, required WorkoutMemo memo}) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    of(userId)[memo.sessionId] = memo;
  }

  @override
  Future<void> delete({
    required String userId,
    required String sessionId,
  }) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    of(userId).remove(sessionId);
  }
}

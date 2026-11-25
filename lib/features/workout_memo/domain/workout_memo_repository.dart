import 'entity/workout_memo.dart';

/// 运动 memo 的保存接口。实现在 data/。
abstract interface class WorkoutMemoRepository {
  /// 按完成时间倒序取最近 [limit] 条。
  Future<List<WorkoutMemo>> fetchRecent({required String userId, int limit});

  /// 整份写入(新建或覆盖)。
  Future<void> save({required String userId, required WorkoutMemo memo});

  Future<void> delete({required String userId, required String sessionId});
}

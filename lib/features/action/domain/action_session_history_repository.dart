import 'entity/action_session_record.dart';

/// 运动会话历史仓库接口(只追加日志)。
/// 实现在 data/firebase_action_session_history_repository.dart。
abstract class ActionSessionHistoryRepository {
  Future<void> recordSession(ActionSessionRecord record);

  /// 按 completedAt 倒序取最近 [limit] 条。
  Future<List<ActionSessionRecord>> fetchRecentSessions({
    required String userId,
    int limit,
  });
}

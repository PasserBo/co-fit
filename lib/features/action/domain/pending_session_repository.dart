import 'entity/pending_session_snapshot.dart';

/// 本机待恢复会话的存取(单槽:一人同一时刻只有一个会话)。
/// 实现:data/shared_preferences_pending_session_repository.dart(线上)、
/// data/in_memory_pending_session_repository.dart(测试)。
abstract class PendingSessionRepository {
  Future<PendingSessionSnapshot?> load();
  Future<void> save(PendingSessionSnapshot snapshot);
  Future<void> clear();
}

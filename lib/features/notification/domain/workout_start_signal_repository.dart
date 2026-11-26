/// 「开始运动」信号:服务端收到后给伙伴推送,处理完即删除。
abstract interface class WorkoutStartSignalRepository {
  Future<void> signal({
    required String userId,
    required String roomId,
    required String sessionId,
    required DateTime startedAt,
  });
}

import '../domain/workout_start_signal_repository.dart';

/// 开始一张卡后留「开始运动」信号,服务端据此推送给伙伴。
/// 调用方 fire-and-forget:失败不能影响运动本身。
class SignalWorkoutStartUsecase {
  SignalWorkoutStartUsecase(this._repository);

  final WorkoutStartSignalRepository _repository;

  Future<void> execute({
    required String userId,
    required String roomId,
    required String sessionId,
    required DateTime startedAt,
  }) {
    final uid = userId.trim();
    final room = roomId.trim();
    final session = sessionId.trim();
    if (uid.isEmpty || room.isEmpty || session.isEmpty) {
      throw ArgumentError('userId / roomId / sessionId must not be empty.');
    }
    return _repository.signal(
      userId: uid,
      roomId: room,
      sessionId: session,
      startedAt: startedAt,
    );
  }
}

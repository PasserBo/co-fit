import '../domain/entity/workout_memo.dart';
import '../domain/workout_memo_repository.dart';

/// 保存一条 memo;内容全空时改为删除(不留空文档)。
class SaveWorkoutMemoUsecase {
  const SaveWorkoutMemoUsecase(this._repository);

  final WorkoutMemoRepository _repository;

  Future<void> execute({required String userId, required WorkoutMemo memo}) {
    if (memo.isEmpty) {
      return _repository.delete(userId: userId, sessionId: memo.sessionId);
    }
    return _repository.save(userId: userId, memo: memo);
  }
}

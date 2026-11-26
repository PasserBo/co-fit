import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/workout_start_signal_repository.dart';

/// users/{uid}/workout_starts/{sessionId}:服务端(functions/ partnerStartPush)
/// 处理后删除。createdAt 用服务端时间,服务端据此丢弃离线补写的旧信号。
class FirebaseWorkoutStartSignalRepository
    implements WorkoutStartSignalRepository {
  FirebaseWorkoutStartSignalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> signal({
    required String userId,
    required String roomId,
    required String sessionId,
    required DateTime startedAt,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workout_starts')
        .doc(sessionId)
        .set({
          'roomId': roomId,
          'startedAt': Timestamp.fromDate(startedAt),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}

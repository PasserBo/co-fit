import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/workout_memo.dart';
import '../domain/workout_memo_repository.dart';

class FirebaseWorkoutMemoRepository implements WorkoutMemoRepository {
  FirebaseWorkoutMemoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('users').doc(userId).collection('session_memos');

  @override
  Future<List<WorkoutMemo>> fetchRecent({
    required String userId,
    int limit = 100,
  }) async {
    final snapshot = await _ref(
      userId,
    ).orderBy('completedAt', descending: true).limit(limit).get();
    return [for (final doc in snapshot.docs) ?WorkoutMemo.fromMap(doc.data())];
  }

  @override
  Future<void> save({required String userId, required WorkoutMemo memo}) {
    return _ref(userId).doc(memo.sessionId).set({
      ...memo.toMap(),
      'completedAt': Timestamp.fromDate(memo.completedAt),
      'updatedAt': Timestamp.fromDate(memo.updatedAt),
    });
  }

  @override
  Future<void> delete({required String userId, required String sessionId}) {
    return _ref(userId).doc(sessionId).delete();
  }
}

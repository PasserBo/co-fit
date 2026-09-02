import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/action_session_history_repository.dart';
import '../domain/entity/action_session_record.dart';

class FirebaseActionSessionHistoryRepository
    implements ActionSessionHistoryRepository {
  FirebaseActionSessionHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('sessions');
  }

  @override
  Future<void> recordSession(ActionSessionRecord record) {
    return _sessionsRef(record.userId).doc(record.sessionId).set({
      ...record.toMap(),
      'startedAt': Timestamp.fromDate(record.startedAt),
      'completedAt': Timestamp.fromDate(record.completedAt),
    });
  }

  @override
  Future<List<ActionSessionRecord>> fetchRecentSessions({
    required String userId,
    int limit = 100,
  }) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final snapshot = await _sessionsRef(trimmed)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => ActionSessionRecord.fromMap(doc.data()))
        .toList(growable: false);
  }
}

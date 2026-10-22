import 'package:cloud_firestore/cloud_firestore.dart';

/// 举报落库:`reports/{autoId}`,只允许创建(rules),客户端不可读。
/// 审核/处理走 Firebase console,首版不做后台。
class FirebaseReportRepository {
  FirebaseReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submit({
    required String reporterId,
    required String roomId,
    String? targetUserId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'roomId': roomId,
      'targetUserId': targetUserId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

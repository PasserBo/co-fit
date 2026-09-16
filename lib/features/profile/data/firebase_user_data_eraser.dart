import 'package:cloud_firestore/cloud_firestore.dart';

/// 账号删除时清空用户在 Firestore 的全部数据(Apple 上架要求)。
/// 房间侧的清理(退出/解散)由 DeleteAccountUsecase 复用 room repository 完成,
/// 这里只负责 users/{uid} 及其子集合。
class FirebaseUserDataEraser {
  FirebaseUserDataEraser({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// 子集合名(rules 里逐个放开了本人 delete)。
  static const _subcollections = ['memberships', 'decks', 'cards', 'sessions'];

  Future<void> eraseUserData({required String userId}) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'userId must not be empty.');
    }
    final userRef = _firestore.collection('users').doc(trimmed);

    for (final name in _subcollections) {
      await _deleteAll(userRef.collection(name));
    }
    await userRef.delete();
  }

  /// 分批删除(Firestore 单批上限 500;会话日志可能很多)。
  Future<void> _deleteAll(CollectionReference<Map<String, dynamic>> ref) async {
    const pageSize = 300;
    while (true) {
      final snapshot = await ref.limit(pageSize).get();
      if (snapshot.docs.isEmpty) {
        return;
      }
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < pageSize) {
        return;
      }
    }
  }
}

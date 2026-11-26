import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/push_device_repository.dart';

/// users/{uid}/devices/{token}:文档 id 就是 token(天然去重)。
class FirebasePushDeviceRepository implements PushDeviceRepository {
  FirebasePushDeviceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId, String token) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token);

  @override
  Future<void> register({required String userId, required String token}) {
    return _doc(userId, token).set({
      'token': token,
      'platform': 'ios',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unregister({required String userId, required String token}) {
    return _doc(userId, token).delete();
  }
}

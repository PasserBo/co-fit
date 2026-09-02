import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/user_profile_entity.dart';
import '../domain/repository/user_profile_repository.dart';

class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  @override
  Stream<UserProfileEntity?> watchProfile(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) {
      return Stream.value(null);
    }
    return _docRef(trimmed).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      // 仅有 memberships 子集合时父文档不存在,与 null 等价;
      // nickname 缺失视为未完成 onboarding。
      if ((data['nickname'] ?? '').toString().trim().isEmpty) {
        return null;
      }
      return UserProfileEntity.fromMap({...data, 'uid': trimmed});
    });
  }

  @override
  Future<void> createProfile(UserProfileEntity profile) {
    return _docRef(profile.uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateProfile(UserProfileEntity profile) {
    return _docRef(profile.uid).set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(mergeFields: ['nickname', 'avatarConfig', 'updatedAt']));
  }
}

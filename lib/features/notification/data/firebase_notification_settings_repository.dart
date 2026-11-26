import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/notification_settings.dart';
import '../domain/notification_settings_repository.dart';

class FirebaseNotificationSettingsRepository
    implements NotificationSettingsRepository {
  FirebaseNotificationSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('settings')
      .doc('notifications');

  @override
  Stream<NotificationSettings> watch({required String userId}) {
    return _doc(
      userId,
    ).snapshots().map((snap) => NotificationSettings.fromMap(snap.data()));
  }

  @override
  Future<void> setPartnerStartEnabled({
    required String userId,
    required bool enabled,
  }) {
    return _doc(userId).set({
      'partnerStartEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setRoomMuted({
    required String userId,
    required String roomId,
    required bool muted,
  }) {
    return _doc(userId).set({
      'mutedRoomIds': muted
          ? FieldValue.arrayUnion([roomId])
          : FieldValue.arrayRemove([roomId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

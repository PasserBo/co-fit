import 'package:cloud_firestore/cloud_firestore.dart';

import 'room_info_model.dart';

class FirebaseRoomRepository {
  FirebaseRoomRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<RoomInfoModel> createRoom({required RoomInfoModel room}) async {
    await _firestore
        .collection('rooms')
        .doc(room.roomId)
        .set(room.toCreateMap());
    return room;
  }

  Future<RoomInfoModel> createRoomWithMembership({
    required RoomInfoModel room,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(room.roomId);
    final membershipRef = _firestore
        .collection('users')
        .doc(room.ownerId)
        .collection('memberships')
        .doc(room.roomId);
    final batch = _firestore.batch();

    batch.set(roomRef, {
      ...room.toCreateMap(),
      'members': {
        room.ownerId: {
          'userId': room.ownerId,
          'role': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
        },
      },
    });
    batch.set(membershipRef, {
      'roomId': room.roomId,
      'userId': room.ownerId,
      'role': 'owner',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return room;
  }

  Future<List<String>> fetchJoinedRoomIds({required String userId}) async {
    final membershipsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('memberships')
        .get();

    final roomIds = membershipsSnapshot.docs
        .map((doc) => doc.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return roomIds;
  }
}

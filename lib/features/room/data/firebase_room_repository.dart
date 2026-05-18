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
    final trimmedRoomId = room.roomId.trim();
    final trimmedOwnerId = room.ownerId.trim();
    if (trimmedRoomId.isEmpty || trimmedOwnerId.isEmpty) {
      throw ArgumentError('roomId and ownerId must not be empty.');
    }

    final roomRef = _firestore.collection('rooms').doc(trimmedRoomId);
    final membershipRef = _firestore
        .collection('users')
        .doc(trimmedOwnerId)
        .collection('memberships')
        .doc(trimmedRoomId);

    final batch = _firestore.batch();
    batch.set(roomRef, {
      ...room.toCreateMap(),
      'members': {
        trimmedOwnerId: {
          'userId': trimmedOwnerId,
          'role': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(membershipRef, {
      'roomId': trimmedRoomId,
      'userId': trimmedOwnerId,
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

  Future<void> joinRoomWithMembership({
    required String roomId,
    required String userId,
  }) async {
    await _joinRoomWithMembership(
      roomId: roomId,
      userId: userId,
      role: 'member',
    );
  }

  Future<void> _joinRoomWithMembership({
    required String roomId,
    required String userId,
    required String role,
  }) async {
    final trimmedRoomId = roomId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedRoomId.isEmpty || trimmedUserId.isEmpty || role.trim().isEmpty) {
      throw ArgumentError('roomId, userId and role must not be empty.');
    }
    if (role != 'owner' && role != 'member') {
      throw ArgumentError('role must be owner or member.');
    }

    final roomRef = _firestore.collection('rooms').doc(trimmedRoomId);
    final membershipRef = _firestore
        .collection('users')
        .doc(trimmedUserId)
        .collection('memberships')
        .doc(trimmedRoomId);
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist: $trimmedRoomId');
    }

    final batch = _firestore.batch();
    batch.set(membershipRef, {
      'roomId': trimmedRoomId,
      'userId': trimmedUserId,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(roomRef, {
      'members.$trimmedUserId': {
        'userId': trimmedUserId,
        'role': role,
        'joinedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}

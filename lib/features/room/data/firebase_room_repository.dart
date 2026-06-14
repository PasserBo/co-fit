import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/room_info_entity.dart';

class FirebaseRoomRepository {
  FirebaseRoomRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<RoomInfoEntity> createRoom({required RoomInfoEntity room}) async {
    await _firestore
        .collection('rooms')
        .doc(room.roomId)
        .set(_toCreateMap(room));
    return room;
  }

  Future<RoomInfoEntity> createRoomWithMembership({
    required RoomInfoEntity room,
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
      ..._toCreateMap(room),
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

  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    final trimmedRoomId = roomId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedRoomId.isEmpty || trimmedUserId.isEmpty) {
      throw ArgumentError('roomId and userId must not be empty.');
    }

    final roomRef = _firestore.collection('rooms').doc(trimmedRoomId);
    final membershipRef = _firestore
        .collection('users')
        .doc(trimmedUserId)
        .collection('memberships')
        .doc(trimmedRoomId);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw StateError('Room does not exist: $trimmedRoomId');
      }

      final roomData = roomSnapshot.data();
      if (roomData == null) {
        throw StateError('Room data is missing: $trimmedRoomId');
      }

      final roomOwnerId = (roomData['ownerId'] ?? '').toString().trim();
      final membershipSnapshot = await transaction.get(membershipRef);

      if (roomOwnerId == trimmedUserId) {
        // Owner membership is created during room creation. Joining again is a no-op.
        return;
      }

      transaction.update(roomRef, {
        'members.$trimmedUserId': {
          'userId': trimmedUserId,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!membershipSnapshot.exists) {
        transaction.set(membershipRef, {
          'roomId': trimmedRoomId,
          'userId': trimmedUserId,
          'role': 'member',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final membershipData = membershipSnapshot.data();
      if (membershipData == null) {
        throw StateError('Membership data is missing for room: $trimmedRoomId');
      }

      final existingRole = (membershipData['role'] ?? '').toString().trim();
      if (existingRole != 'member') {
        throw StateError(
          'Membership role mismatch. Expected member, got: $existingRole',
        );
      }

      transaction.update(membershipRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Map<String, dynamic> _toCreateMap(RoomInfoEntity room) {
    return {
      ...room.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

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
}

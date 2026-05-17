import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_room_repository.dart';

final firebaseRoomRepositoryProvider = Provider<FirebaseRoomRepository>((ref) {
  return FirebaseRoomRepository();
});

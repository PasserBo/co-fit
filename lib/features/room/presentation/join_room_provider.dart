import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository_provider.dart';
import '../usecase/join_room_usecase.dart';

final joinRoomUsecaseProvider = Provider<JoinRoomUsecase>((ref) {
  return JoinRoomUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

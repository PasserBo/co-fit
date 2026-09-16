import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_repository_provider.dart';
import '../../room/data/room_repository_provider.dart';
import '../data/firebase_user_data_eraser.dart';
import '../usecase/delete_account_usecase.dart';

final userDataEraserProvider = Provider<FirebaseUserDataEraser>((ref) {
  return FirebaseUserDataEraser();
});

final deleteAccountUsecaseProvider = Provider<DeleteAccountUsecase>((ref) {
  return DeleteAccountUsecase(
    authRepository: ref.watch(authRepositoryProvider),
    roomRepository: ref.watch(firebaseRoomRepositoryProvider),
    userDataEraser: ref.watch(userDataEraserProvider),
  );
});

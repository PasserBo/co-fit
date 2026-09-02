import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../usecase/register_usecase.dart';
import '../usecase/send_password_reset_usecase.dart';
import '../usecase/sign_in_usecase.dart';
import '../usecase/sign_in_with_google_usecase.dart';
import '../usecase/sign_out_usecase.dart';
import '../usecase/watch_auth_state_usecase.dart';
import 'auth_repository_provider.dart';

final watchAuthStateUsecaseProvider = Provider<WatchAuthStateUsecase>((ref) {
  return WatchAuthStateUsecase(ref.watch(authRepositoryProvider));
});

final signInUsecaseProvider = Provider<SignInUsecase>((ref) {
  return SignInUsecase(ref.watch(authRepositoryProvider));
});

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUsecaseProvider = Provider<SignInWithGoogleUsecase>((
  ref,
) {
  return SignInWithGoogleUsecase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUsecaseProvider = Provider<SendPasswordResetUsecase>((
  ref,
) {
  return SendPasswordResetUsecase(ref.watch(authRepositoryProvider));
});

final signOutUsecaseProvider = Provider<SignOutUsecase>((ref) {
  return SignOutUsecase(ref.watch(authRepositoryProvider));
});

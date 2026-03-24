import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_auth_repository.dart';

class WatchAuthStateUsecase {
  WatchAuthStateUsecase(this._repository);

  final FirebaseAuthRepository _repository;

  Stream<User?> execute() {
    return _repository.authStateChanges();
  }
}

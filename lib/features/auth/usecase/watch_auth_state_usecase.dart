import 'package:firebase_auth/firebase_auth.dart';

import '../domain/repository/auth_repository.dart';

class WatchAuthStateUsecase {
  WatchAuthStateUsecase(this._repository);

  final AuthRepository _repository;

  Stream<User?> execute() {
    return _repository.authStateChanges();
  }
}

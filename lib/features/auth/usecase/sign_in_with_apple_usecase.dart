import 'package:firebase_auth/firebase_auth.dart';

import '../domain/repository/auth_repository.dart';

class SignInWithAppleUsecase {
  SignInWithAppleUsecase(this._repository);

  final AuthRepository _repository;

  Future<UserCredential> execute() {
    return _repository.signInWithApple();
  }
}

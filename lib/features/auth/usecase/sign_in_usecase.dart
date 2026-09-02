import 'package:firebase_auth/firebase_auth.dart';

import '../domain/repository/auth_repository.dart';

class SignInUsecase {
  SignInUsecase(this._repository);

  final AuthRepository _repository;

  Future<UserCredential> execute({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

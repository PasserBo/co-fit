import 'package:firebase_auth/firebase_auth.dart';

import '../domain/repository/auth_repository.dart';

class RegisterUsecase {
  RegisterUsecase(this._repository);

  final AuthRepository _repository;

  Future<UserCredential> execute({
    required String email,
    required String password,
  }) {
    return _repository.registerWithEmail(email: email, password: password);
  }
}

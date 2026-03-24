import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_auth_repository.dart';

class RegisterUsecase {
  RegisterUsecase(this._repository);

  final FirebaseAuthRepository _repository;

  Future<UserCredential> execute({
    required String email,
    required String password,
  }) {
    return _repository.register(email: email, password: password);
  }
}

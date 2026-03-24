import '../data/firebase_auth_repository.dart';

class SignOutUsecase {
  SignOutUsecase(this._repository);

  final FirebaseAuthRepository _repository;

  Future<void> execute() {
    return _repository.signOut();
  }
}

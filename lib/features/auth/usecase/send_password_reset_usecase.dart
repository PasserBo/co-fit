import '../domain/repository/auth_repository.dart';

class SendPasswordResetUsecase {
  SendPasswordResetUsecase(this._repository);

  final AuthRepository _repository;

  Future<void> execute({required String email}) {
    return _repository.sendPasswordResetEmail(email: email.trim());
  }
}

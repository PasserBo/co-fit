import '../domain/repository/auth_repository.dart';

class SignOutUsecase {
  SignOutUsecase(this._repository);

  final AuthRepository _repository;

  Future<void> execute() {
    return _repository.signOut();
  }
}

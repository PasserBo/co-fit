import '../domain/entity/user_profile_entity.dart';
import '../domain/repository/user_profile_repository.dart';

class UpdateProfileUsecase {
  UpdateProfileUsecase(this._repository);

  final UserProfileRepository _repository;

  Future<void> execute(UserProfileEntity profile) {
    final trimmedNickname = profile.nickname.trim();
    if (trimmedNickname.isEmpty ||
        trimmedNickname.length > UserProfileEntity.nicknameMaxLength) {
      throw ArgumentError.value(
        profile.nickname,
        'nickname',
        'Nickname must be 1..${UserProfileEntity.nicknameMaxLength} '
            'characters.',
      );
    }
    return _repository.updateProfile(
      profile.copyWith(nickname: trimmedNickname),
    );
  }
}

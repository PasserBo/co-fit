import '../domain/entity/user_profile_entity.dart';
import '../domain/repository/user_profile_repository.dart';

class CompleteOnboardingUsecase {
  CompleteOnboardingUsecase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfileEntity> execute({
    required String uid,
    required String nickname,
  }) async {
    final trimmedUid = uid.trim();
    final trimmedNickname = nickname.trim();

    if (trimmedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'uid must not be empty.');
    }
    if (trimmedNickname.isEmpty) {
      throw ArgumentError.value(
        nickname,
        'nickname',
        'Nickname must not be empty.',
      );
    }
    if (trimmedNickname.length > UserProfileEntity.nicknameMaxLength) {
      throw ArgumentError.value(
        nickname,
        'nickname',
        'Nickname must be at most '
            '${UserProfileEntity.nicknameMaxLength} characters.',
      );
    }

    final profile = UserProfileEntity(
      uid: trimmedUid,
      nickname: trimmedNickname,
    );
    await _repository.createProfile(profile);
    return profile;
  }
}

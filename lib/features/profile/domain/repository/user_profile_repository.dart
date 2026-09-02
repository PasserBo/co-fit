import '../entity/user_profile_entity.dart';

/// 用户资料仓库接口。实现在 data/firebase_user_profile_repository.dart。
abstract class UserProfileRepository {
  /// 监听 users/{uid}。文档不存在时发出 null(用于 onboarding 门控)。
  Stream<UserProfileEntity?> watchProfile(String uid);

  Future<void> createProfile(UserProfileEntity profile);

  Future<void> updateProfile(UserProfileEntity profile);
}

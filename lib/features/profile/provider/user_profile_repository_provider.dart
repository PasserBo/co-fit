import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_user_profile_repository.dart';
import '../domain/repository/user_profile_repository.dart';
import '../usecase/complete_onboarding_usecase.dart';
import '../usecase/update_profile_usecase.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirebaseUserProfileRepository();
});

final completeOnboardingUsecaseProvider = Provider<CompleteOnboardingUsecase>((
  ref,
) {
  return CompleteOnboardingUsecase(ref.watch(userProfileRepositoryProvider));
});

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  return UpdateProfileUsecase(ref.watch(userProfileRepositoryProvider));
});

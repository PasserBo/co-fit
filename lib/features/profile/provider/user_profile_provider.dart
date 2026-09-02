import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_state_provider.dart';
import '../domain/entity/user_profile_entity.dart';
import 'user_profile_repository_provider.dart';

/// 当前登录用户的资料流。
/// - 未登录 → null
/// - 已登录但 users/{uid} 不存在 → null(AuthGate 据此进入 onboarding)
final userProfileProvider = StreamProvider<UserProfileEntity?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(userProfileRepositoryProvider).watchProfile(user.uid);
});

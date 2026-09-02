import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/provider/user_profile_provider.dart';

/// 自己的昵称(G5 决议:昵称随 presence data 下发,零额外读库)。
/// 读取方:AblyRuntimeNotifier(enter/重申)与 OwnActionSessionNotifier(activity 更新)。
/// profile 未加载时为 null,读侧回退 uid 截断展示。
final ownNicknameProvider = Provider<String?>((ref) {
  final nickname = ref.watch(userProfileProvider).value?.nickname.trim();
  return (nickname == null || nickname.isEmpty) ? null : nickname;
});

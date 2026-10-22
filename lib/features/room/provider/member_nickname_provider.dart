import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/provider/user_profile_repository_provider.dart';

/// 任意成员的昵称(按 uid 读 users/{uid},rules 对登录用户放开 read)。
/// presence 在线成员已随 presence 下发昵称(G5),本 provider 供离线成员
/// (成员管理 / 举报对象列表)使用;无 profile 时为 null,读侧回退 uid 截断。
final memberNicknameProvider = StreamProvider.family<String?, String>((
  ref,
  uid,
) {
  return ref.watch(userProfileRepositoryProvider).watchProfile(uid).map((p) {
    final nickname = p?.nickname.trim();
    return (nickname == null || nickname.isEmpty) ? null : nickname;
  });
});

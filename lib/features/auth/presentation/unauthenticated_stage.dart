import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 未登录时 AuthGate 要渲染的阶段。
enum UnauthenticatedStage { splash, welcomeTour, login }

/// 未登录分支的决策(纯函数,便于把规格场景直接写成单测):
///
/// 1. 有滞留的邀请链接 → 登录页(邀请优先于演示;登录后由 InviteLinkGate 消费)。
/// 2. 「演示已看过」还没读出来 → splash(不能先闪一帧登录页再切到演示)。
/// 3. 未看过 → 演示房间。
/// 4. 已看过,或标记读取出错 → 登录页(读不到标记就按老用户对待,宁可少演示一次)。
UnauthenticatedStage resolveUnauthenticatedStage({
  required bool hasPendingInvite,
  required AsyncValue<bool> tourSeen,
}) {
  if (hasPendingInvite) {
    return UnauthenticatedStage.login;
  }
  if (tourSeen.hasError) {
    return UnauthenticatedStage.login;
  }
  final seen = tourSeen.value;
  if (seen == null) {
    return UnauthenticatedStage.splash;
  }
  return seen ? UnauthenticatedStage.login : UnauthenticatedStage.welcomeTour;
}

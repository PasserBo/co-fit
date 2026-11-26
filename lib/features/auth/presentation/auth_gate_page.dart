import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_shell.dart';
import '../../../core/theme/cofit_dimens.dart';
import '../../../core/widget/brand_splash.dart';
import '../../action/presentation/view/card_library_page.dart';
import '../../invite/presentation/invite_link_gate.dart';
import '../../invite/provider/pending_invite_provider.dart';
import '../../notification/presentation/push_lifecycle_binder.dart';
import '../../profile/presentation/view/onboarding_page_view.dart';
import '../../profile/provider/user_profile_provider.dart';
import '../../room/presentation/view/room_main_view.dart';
import '../../welcome_tour/presentation/view/welcome_tour_view.dart';
import '../../welcome_tour/provider/welcome_tour_providers.dart';
import '../provider/auth_state_provider.dart';
import '../provider/auth_usecase_providers.dart';
import 'unauthenticated_stage.dart';
import 'user_bootstrap_provider.dart';
import 'view/login_page_view.dart';
import 'view/my_page_view.dart';

/// 门控:
///   authState loading                  → splash
///   user == null(并清理 bootstrap):
///     有滞留邀请链接                   → LoginPageView(并标记演示已看过)
///     演示已看过标记加载中             → splash(防闪登录页)
///     未看过                           → WelcomeTourView(登录前演示房间)
///     已看过                           → LoginPageView
///   (决策见 [resolveUnauthenticatedStage];登录成功即标记演示已看过,
///    退出登录后不再出现演示。)
///   user != null, profile 加载中       → splash(防闪 onboarding)
///   profile == null                    → OnboardingPageView
///   profile != null, bootstrap 未放行  → splash(带阶段文案;防闪「没有加入任何房间」)
///   bootstrap 放行                     → AppShell
/// 各态之间用 [CoFitMotion.splashFade] 交叉淡出。
class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  String? _bootstrappedUserId;
  bool _isClearScheduled = false;
  bool _isTourMarkScheduled = false;

  static const _splashKey = ValueKey('gate_splash');
  static const _loginKey = ValueKey('gate_login');
  static const _onboardingKey = ValueKey('gate_onboarding');
  static const _tourKey = ValueKey('gate_welcome_tour');
  static const _shellKey = ValueKey('gate_shell');

  void _scheduleClear() {
    _bootstrappedUserId = null;
    if (_isClearScheduled) {
      return;
    }
    _isClearScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isClearScheduled = false;
      if (!mounted) {
        return;
      }
      ref.read(userBootstrapProvider.notifier).clear();
    });
  }

  /// 把「演示已看过」落下去(登录成功 / 邀请链接优先时)。
  /// 幂等:已是 true 就不再调;build 中不能改 provider,所以推到帧后。
  void _scheduleTourSeen() {
    if (_isTourMarkScheduled ||
        ref.read(welcomeTourSeenProvider).value == true) {
      return;
    }
    _isTourMarkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isTourMarkScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(ref.read(welcomeTourSeenProvider.notifier).markSeen());
    });
  }

  void _scheduleBootstrap(String userId) {
    if (_bootstrappedUserId == userId) {
      return;
    }
    _bootstrappedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(userBootstrapProvider.notifier).bootstrap(userId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: CoFitMotion.splashFade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildStage(),
    );
  }

  Widget _buildStage() {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading && !authState.hasValue) {
      return const BrandSplash(key: _splashKey);
    }

    final user = authState.value;
    if (user == null) {
      _scheduleClear();
      return _buildUnauthenticated();
    }
    return _buildLoggedIn(user);
  }

  Widget _buildUnauthenticated() {
    final hasPendingInvite = ref.watch(pendingInviteProvider) != null;
    final tourSeen = ref.watch(welcomeTourSeenProvider);
    final stage = resolveUnauthenticatedStage(
      hasPendingInvite: hasPendingInvite,
      tourSeen: tourSeen,
    );
    if (hasPendingInvite) {
      // 邀请链接优先:这次不演示,之后也不再演示。
      _scheduleTourSeen();
    }
    return switch (stage) {
      UnauthenticatedStage.splash => const BrandSplash(key: _splashKey),
      UnauthenticatedStage.welcomeTour => const WelcomeTourView(key: _tourKey),
      UnauthenticatedStage.login => const LoginPageView(key: _loginKey),
    };
  }

  Widget _buildLoggedIn(User user) {
    // 登录成功即视为看过演示:退出登录后回到登录页而不是演示;
    // 老用户升级到带演示的版本时也在这里打标,不会在退出后突然看到演示。
    _scheduleTourSeen();
    final profileState = ref.watch(userProfileProvider);

    // profile 首帧 loading 不得先渲 onboarding(防闪)。
    if (profileState.isLoading && !profileState.hasValue) {
      return const BrandSplash(key: _splashKey);
    }
    final profile = profileState.value;
    if (profile == null) {
      return OnboardingPageView(key: _onboardingKey, userId: user.uid);
    }

    _scheduleBootstrap(user.uid);

    // 启动数据(实时连接 / 已加入房间 / 卡牌牌组 / 会话恢复)没就绪前停在 splash,
    // 否则房间页会先闪一帧「没有加入任何房间」空态。超时兜底见 UserBootstrapNotifier。
    final bootstrap = ref.watch(userBootstrapProvider);
    final gateOpen = bootstrap.userId == user.uid && bootstrap.isGateOpen;
    if (!gateOpen) {
      return BrandSplash(
        key: _splashKey,
        statusText: bootstrap.phase.splashLabel,
      );
    }

    // 槽位顺序与 AppShell.destinations 一致:房间 / 牌库 / 我的
    return InviteLinkGate(
      key: _shellKey,
      userId: user.uid,
      child: PushLifecycleBinder(
        userId: user.uid,
        child: AppShell(
          pages: [
            RoomMainView(userId: user.uid),
            const CardLibraryPage(),
            MyPageView(
              user: user,
              signOutUsecase: ref.watch(signOutUsecaseProvider),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_shell.dart';
import '../../action/presentation/view/card_library_page.dart';
import '../../invite/presentation/invite_link_gate.dart';
import '../../profile/presentation/view/onboarding_page_view.dart';
import '../../profile/provider/user_profile_provider.dart';
import '../../room/presentation/view/room_main_view.dart';
import '../provider/auth_state_provider.dart';
import '../provider/auth_usecase_providers.dart';
import 'user_bootstrap_provider.dart';
import 'view/login_page_view.dart';
import 'view/my_page_view.dart';

/// 三态门控:
///   authState loading            → splash
///   user == null                 → LoginPageView(并清理 bootstrap)
///   user != null, profile 加载中 → splash(防闪 onboarding)
///   profile == null              → OnboardingPageView
///   profile != null              → bootstrap + AppShell
class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  String? _bootstrappedUserId;
  bool _isClearScheduled = false;

  static const _splash = Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

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
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading && !authState.hasValue) {
      return _splash;
    }

    final user = authState.value;
    if (user == null) {
      _scheduleClear();
      return const LoginPageView();
    }
    return _buildLoggedIn(user);
  }

  Widget _buildLoggedIn(User user) {
    final profileState = ref.watch(userProfileProvider);

    // profile 首帧 loading 不得先渲 onboarding(防闪)。
    if (profileState.isLoading && !profileState.hasValue) {
      return _splash;
    }
    final profile = profileState.value;
    if (profile == null) {
      return OnboardingPageView(userId: user.uid);
    }

    _scheduleBootstrap(user.uid);

    // 槽位顺序与 AppShell.destinations 一致:房间 / 牌库 / 我的
    return InviteLinkGate(
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
    );
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../usecase/register_usecase.dart';
import '../usecase/sign_in_usecase.dart';
import '../usecase/sign_out_usecase.dart';
import '../usecase/watch_auth_state_usecase.dart';
import 'auth_login_page.dart';
import 'auth_home_page.dart';
import 'user_bootstrap_provider.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  late final FirebaseAuthRepository _repository;
  late final WatchAuthStateUsecase _watchAuthStateUsecase;
  late final SignInUsecase _signInUsecase;
  late final RegisterUsecase _registerUsecase;
  late final SignOutUsecase _signOutUsecase;
  String? _bootstrappedUserId;
  bool _isClearScheduled = false;

  @override
  void initState() {
    super.initState();
    _repository = FirebaseAuthRepository();
    _watchAuthStateUsecase = WatchAuthStateUsecase(_repository);
    _signInUsecase = SignInUsecase(_repository);
    _registerUsecase = RegisterUsecase(_repository);
    _signOutUsecase = SignOutUsecase(_repository);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _watchAuthStateUsecase.execute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          _bootstrappedUserId = null;
          if (!_isClearScheduled) {
            _isClearScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _isClearScheduled = false;
              if (!mounted) {
                return;
              }
              ref.read(userBootstrapProvider.notifier).clear();
            });
          }
          return AuthLoginPage(
            signInUsecase: _signInUsecase,
            registerUsecase: _registerUsecase,
          );
        }

        if (_bootstrappedUserId != user.uid) {
          _bootstrappedUserId = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            unawaited(
              ref.read(userBootstrapProvider.notifier).bootstrap(user.uid),
            );
          });
        }

        return AuthHomePage(user: user, signOutUsecase: _signOutUsecase);
      },
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_auth_repository.dart';
import '../usecase/register_usecase.dart';
import '../usecase/sign_in_usecase.dart';
import '../usecase/sign_out_usecase.dart';
import '../usecase/watch_auth_state_usecase.dart';
import 'auth_login_page.dart';
import 'auth_home_page.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  late final FirebaseAuthRepository _repository;
  late final WatchAuthStateUsecase _watchAuthStateUsecase;
  late final SignInUsecase _signInUsecase;
  late final RegisterUsecase _registerUsecase;
  late final SignOutUsecase _signOutUsecase;

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
          return AuthLoginPage(
            signInUsecase: _signInUsecase,
            registerUsecase: _registerUsecase,
          );
        }

        return AuthHomePage(
          user: user,
          signOutUsecase: _signOutUsecase,
        );
      },
    );
  }
}

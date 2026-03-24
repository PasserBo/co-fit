import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../usecase/sign_out_usecase.dart';

class AuthHomePage extends StatelessWidget {
  const AuthHomePage({
    required this.user,
    required this.signOutUsecase,
    super.key,
  });

  final User user;
  final SignOutUsecase signOutUsecase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoFit'),
        actions: [
          IconButton(
            onPressed: () async {
              await signOutUsecase.execute();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Logged in as\n${user.email ?? 'Anonymous'}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

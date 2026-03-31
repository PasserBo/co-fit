import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../usecase/sign_out_usecase.dart';

class AuthMyPage extends StatelessWidget {
  const AuthMyPage({
    required this.user,
    required this.signOutUsecase,
    super.key,
  });

  final User user;
  final SignOutUsecase signOutUsecase;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'My Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user.email ?? 'Anonymous user'),
          subtitle: const Text('Account'),
        ),
        const Divider(height: 32),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.palette_outlined),
          title: Text('Theme'),
          subtitle: Text('Coming soon'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.notifications_outlined),
          title: Text('Notifications'),
          subtitle: Text('Coming soon'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('Privacy'),
          subtitle: Text('Coming soon'),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await signOutUsecase.execute();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

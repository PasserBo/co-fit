import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../room/presentation/room_browse_page.dart';
import '../../room/presentation/room_community_page.dart';
import '../usecase/sign_out_usecase.dart';
import 'auth_my_page.dart';

class AuthHomePage extends StatefulWidget {
  const AuthHomePage({
    required this.user,
    required this.signOutUsecase,
    super.key,
  });

  final User user;
  final SignOutUsecase signOutUsecase;

  @override
  State<AuthHomePage> createState() => _AuthHomePageState();
}

class _AuthHomePageState extends State<AuthHomePage> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      RoomCommunityPage(userId: widget.user.uid),
      RoomBrowsePage(userId: widget.user.uid),
      AuthMyPage(
        user: widget.user,
        signOutUsecase: widget.signOutUsecase,
      ),
    ];

    final titles = ['Community', 'Browser', 'My Page'];

    return Scaffold(
      appBar: AppBar(
        title: Text('CoFit - ${titles[_selectedIndex]}'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Browser',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'My Page',
          ),
        ],
      ),
    );
  }
}

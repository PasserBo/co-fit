import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../room/presentation/room_main_page.dart';
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const RoomMainPage(),
      AuthMyPage(
        user: widget.user,
        signOutUsecase: widget.signOutUsecase,
      ),
    ];

    final titles = ['Rooms', 'My Page'];

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
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Rooms',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/auth_gate_page.dart';
import 'firestore/ably_state_machine.dart';
import 'firestore/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  runApp(const ProviderScope(child: CoFitApp()));
}

class CoFitApp extends StatelessWidget {
  const CoFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AblyLifecycleBinder(
      child: MaterialApp(
        title: 'CoFit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: const AuthGatePage(),
      ),
    );
  }
}

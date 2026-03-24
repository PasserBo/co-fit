import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_gate_page.dart';
import 'firestore/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  runApp(const CoFitApp());
}

class CoFitApp extends StatelessWidget {
  const CoFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoFit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const AuthGatePage(),
    );
  }
}

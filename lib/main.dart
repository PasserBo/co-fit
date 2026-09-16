import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/cofit_theme.dart';
import 'features/auth/presentation/auth_gate_page.dart';
import 'firestore/ably_state_machine.dart';
import 'firestore/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseInitializer.initialize();
  } catch (error, stackTrace) {
    // 启动失败不再白屏:把原因摊在屏幕上(可复制)。
    runApp(StartupErrorApp(error: '$error', stackTrace: '$stackTrace'));
    return;
  }
  runApp(const ProviderScope(child: CoFitApp()));
}

/// 初始化失败时的兜底界面 —— 白屏是最难排查的故障态,这里必须给出原因。
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.error,
    required this.stackTrace,
    super.key,
  });

  final String error;
  final String stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoFit',
      theme: CoFitTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const Text(
                  '启动失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SelectableText(error),
                const SizedBox(height: 20),
                SelectableText(
                  stackTrace,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoFitApp extends StatelessWidget {
  const CoFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AblyLifecycleBinder(
      child: MaterialApp(
        title: 'CoFit',
        theme: CoFitTheme.dark,
        navigatorKey: appNavigatorKey,
        home: const AuthGatePage(),
      ),
    );
  }
}

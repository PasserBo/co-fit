import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_usecase_providers.dart';

/// Firebase 登录态流。AuthGate 据此做 登录页/onboarding/主壳 三态门控。
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(watchAuthStateUsecaseProvider).execute();
});

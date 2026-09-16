import 'package:firebase_auth/firebase_auth.dart';

/// 用户主动取消第三方登录(关闭系统弹窗)。UI 层捕获后静默返回,不展示错误。
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// 认证仓库接口。实现在 data/firebase_auth_repository.dart。
///
/// Sign in with Apple 延后到 E1-Apple 轨道（等付费开发者账号就绪）再加入本接口。
abstract class AuthRepository {
  Stream<User?> authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithGoogle();

  Future<UserCredential> signInWithApple();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}

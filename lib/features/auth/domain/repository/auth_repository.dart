import 'package:firebase_auth/firebase_auth.dart';

/// 用户主动取消第三方登录(关闭系统弹窗)。UI 层捕获后静默返回,不展示错误。
/// 邮箱账号需要用户重新登录后才能删除(Firebase requires-recent-login)。
class ReauthenticationRequiredException implements Exception {
  const ReauthenticationRequiredException();

  @override
  String toString() => 'ReauthenticationRequiredException';
}

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

  /// 账号删除前的重新认证(Firebase 要求近期登录)。
  /// 返回 Apple 授权码(仅 Apple 账号有,用于 token 撤销);其他 provider 返回 null。
  /// 邮箱账号无法静默重认证 → 抛 [ReauthenticationRequiredException],由 UI 引导重登。
  Future<String?> reauthenticate();

  /// 删除 Firebase Auth 用户;[appleAuthorizationCode] 非空时同时撤销 Apple token
  /// (Apple 对「支持账号删除」的强制要求)。
  Future<void> deleteAccount({String? appleAuthorizationCode});
}

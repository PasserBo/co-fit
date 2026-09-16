import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/repository/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitialization;

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 走一次 Google 原生授权并换成 Firebase 凭证(登录与重认证共用)。
  Future<AuthCredential> _obtainGoogleCredential() async {
    // google_sign_in v7:initialize 全局仅需一次,iOS 端 clientId 取自
    // GoogleService-Info.plist,无需显式传参。
    _googleInitialization ??= _googleSignIn.initialize();
    await _googleInitialization;

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google sign-in did not return an idToken.',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    return _firebaseAuth.signInWithCredential(await _obtainGoogleCredential());
  }

  /// 走一次 Apple 原生授权,返回 (Firebase 凭证, Apple 授权码)。
  /// 登录与「删除账号前重认证」共用 —— 后者需要新鲜的授权码来撤销 token。
  Future<(OAuthCredential, String)> _obtainAppleCredential() async {
    // 防重放:rawNonce 给 Firebase,sha256(rawNonce) 给 Apple。
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      // ⚠️ Firebase 校验 Apple 凭证时必须带授权码。只传 idToken + rawNonce
      // 会报 "Invalid OAuth response from apple.com"(invalid-credential),
      // 且报错文案会把排查方向误导到 Firebase/Apple 的 provider 配置上。
      // 见 flutterfire#18289 / #13235。
      accessToken: appleCredential.authorizationCode,
    );
    return (credential, appleCredential.authorizationCode);
  }

  @override
  Future<String?> reauthenticate() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ReauthenticationRequiredException();
    }
    final providers =
        user.providerData.map((info) => info.providerId).toSet();

    if (providers.contains('apple.com')) {
      final (credential, authorizationCode) = await _obtainAppleCredential();
      await user.reauthenticateWithCredential(credential);
      return authorizationCode;
    }
    if (providers.contains('google.com')) {
      await user.reauthenticateWithCredential(await _obtainGoogleCredential());
      return null;
    }
    // 邮箱账号需要密码,静默重认证做不到 → 交给 UI 引导重新登录。
    throw const ReauthenticationRequiredException();
  }

  @override
  Future<void> deleteAccount({String? appleAuthorizationCode}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    // Apple 要求「支持账号删除」的 app 必须撤销 token;撤销失败不应阻断删除。
    if (appleAuthorizationCode != null) {
      try {
        await _firebaseAuth.revokeTokenWithAuthorizationCode(
          appleAuthorizationCode,
        );
      } catch (_) {
        // 忽略:token 会随 Apple 侧过期失效,账号本身必须删掉。
      }
    }
    await user.delete();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google 未登录时忽略。
    }
  }

  @override
  Future<UserCredential> signInWithApple() async {
    final (credential, _) = await _obtainAppleCredential();
    return _firebaseAuth.signInWithCredential(credential);
  }

  static String _generateNonce() {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      32,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    // Google 会话一并注销,避免下次 authenticate 静默复用上一个账号。
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google 未初始化/未登录时忽略,不阻塞 Firebase 登出。
    }
    await _firebaseAuth.signOut();
  }
}

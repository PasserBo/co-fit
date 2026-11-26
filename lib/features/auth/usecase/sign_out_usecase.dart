import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/repository/auth_repository.dart';

/// 退出登录前要做、且必须在仍登录时做的事(例如撤掉本设备的推送登记)。
typedef BeforeSignOutHook = Future<void> Function(String userId);

class SignOutUsecase {
  SignOutUsecase(
    this._repository, {
    List<BeforeSignOutHook> beforeSignOut = const [],
    String? Function()? currentUserId,
    Duration hookTimeout = const Duration(seconds: 5),
  }) : _beforeSignOut = beforeSignOut,
       _currentUserId = currentUserId,
       _hookTimeout = hookTimeout;

  final AuthRepository _repository;
  final List<BeforeSignOutHook> _beforeSignOut;
  final String? Function()? _currentUserId;
  final Duration _hookTimeout;

  /// 钩子失败或超时(离线)不阻止退出登录。
  Future<void> execute() async {
    final userId = _currentUserId?.call();
    if (userId != null && userId.isNotEmpty) {
      for (final hook in _beforeSignOut) {
        try {
          await hook(userId).timeout(_hookTimeout);
        } catch (e) {
          debugPrint('beforeSignOut hook failed: $e');
        }
      }
    }
    return _repository.signOut();
  }
}

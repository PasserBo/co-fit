import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/entity/push_message.dart';
import '../domain/entity/push_permission_status.dart';
import '../domain/push_messaging_gateway.dart';

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// 前台不弹(spec: 前台不弹出):伙伴的小人本来就在眼前。
  static Future<void> configureForegroundPresentation() {
    return FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
  }

  static PushPermissionStatus _map(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermissionStatus.authorized,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
    };
  }

  @override
  Future<PushPermissionStatus> permissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<String?> token() async {
    // iOS:APNs token 到位前 getToken 会抛错;等一下再取,仍没有就放弃(下次同步再来)。
    var apns = await _messaging.getAPNSToken();
    for (var i = 0; apns == null && i < 3; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      apns = await _messaging.getAPNSToken();
    }
    if (apns == null) {
      debugPrint('push: APNs token unavailable');
      return null;
    }
    return _messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushMessage(message.data);
  }

  @override
  Stream<PushMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => PushMessage(m.data));
}

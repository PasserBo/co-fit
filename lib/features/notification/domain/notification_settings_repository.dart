import 'entity/notification_settings.dart';

abstract interface class NotificationSettingsRepository {
  /// 本人的推送设置;文档不存在时发 [NotificationSettings.defaults]。
  Stream<NotificationSettings> watch({required String userId});

  Future<void> setPartnerStartEnabled({
    required String userId,
    required bool enabled,
  });

  Future<void> setRoomMuted({
    required String userId,
    required String roomId,
    required bool muted,
  });
}

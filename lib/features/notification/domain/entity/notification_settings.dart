// Firestore 文档: users/{uid}/settings/notifications(change add-partner-start-push)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';

/// 推送设置。文档不存在 = 开、无静音。服务端按它决定发不发(design.md §2)。
@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const NotificationSettings._();

  const factory NotificationSettings({
    /// 伙伴开始运动时推送我。
    @Default(true) bool partnerStartEnabled,

    /// 静音的房间:这些房间里伙伴开始运动不推送。
    @Default(<String>{}) Set<String> mutedRoomIds,
  }) = _NotificationSettings;

  static const NotificationSettings defaults = NotificationSettings();

  bool isRoomMuted(String roomId) => mutedRoomIds.contains(roomId);

  /// 字段缺失 / 类型不对按默认值处理(与服务端 parseSettings 一致)。
  factory NotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return defaults;
    }
    final muted = map['mutedRoomIds'];
    return NotificationSettings(
      partnerStartEnabled: map['partnerStartEnabled'] != false,
      mutedRoomIds: {
        if (muted is List)
          for (final id in muted)
            if (id is String && id.isNotEmpty) id,
      },
    );
  }
}

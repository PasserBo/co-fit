import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_activity_status_entity.dart';

part 'room_presence_member.freezed.dart';

@freezed
abstract class RoomPresenceMember with _$RoomPresenceMember {
  const factory RoomPresenceMember({
    required String clientId,
    required String userId,

    /// 随 presence data 下发的昵称(G5);无 profile 或旧客户端时为 null,
    /// 展示层回退 uid 截断。
    String? nickname,
    @Default(
      UserActivityStatusEntity(activityState: UserActivityState.idle),
    )
    UserActivityStatusEntity activityStatus,
  }) = _RoomPresenceMember;

  factory RoomPresenceMember.fromMap(Map<String, dynamic> map) {
    final clientId = map['clientId']?.toString() ?? 'unknown';
    final userId = map['userId']?.toString() ?? clientId;
    final memberData = map['data'];

    Object? activityPayload;
    String? nickname;
    if (memberData is Map) {
      activityPayload = memberData['activity'] ?? memberData;
      final rawNickname = memberData['nickname']?.toString().trim();
      nickname =
          (rawNickname == null || rawNickname.isEmpty) ? null : rawNickname;
    } else if (map['activity'] != null) {
      activityPayload = map['activity'];
    }

    return RoomPresenceMember(
      clientId: clientId,
      userId: userId,
      nickname: nickname,
      activityStatus: UserActivityStatusEntity.fromRawPayload(activityPayload),
    );
  }
}

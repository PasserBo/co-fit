import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_activity_status_entity.dart';

part 'room_presence_member.freezed.dart';

@freezed
abstract class RoomPresenceMember with _$RoomPresenceMember {
  const factory RoomPresenceMember({
    required String clientId,
    required String userId,
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
    if (memberData is Map<String, dynamic>) {
      activityPayload = memberData['activity'] ?? memberData;
    } else if (memberData is Map) {
      activityPayload = memberData['activity'] ?? memberData;
    } else if (map['activity'] != null) {
      activityPayload = map['activity'];
    }

    return RoomPresenceMember(
      clientId: clientId,
      userId: userId,
      activityStatus: UserActivityStatusEntity.fromRawPayload(activityPayload),
    );
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_activity_status_entity.freezed.dart';

enum UserActivityState {
  idle,
  active,
  paused;

  static UserActivityState fromRaw(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    switch (value) {
      case 'active':
        return UserActivityState.active;
      case 'paused':
        return UserActivityState.paused;
      default:
        return UserActivityState.idle;
    }
  }
}

@freezed
abstract class UserActivityStatusEntity with _$UserActivityStatusEntity {
  const factory UserActivityStatusEntity({
    required UserActivityState activityState,
    String? actionKey,
    int? durationSec,
    int? remainingSec,
    String? sessionId,
    String? templateId,
    String? templateName,
    int? updatedAtEpochMs,
  }) = _UserActivityStatusEntity;

  factory UserActivityStatusEntity.idle() {
    return const UserActivityStatusEntity(activityState: UserActivityState.idle);
  }

  factory UserActivityStatusEntity.fromMap(Map<String, dynamic> map) {
    return UserActivityStatusEntity(
      activityState: UserActivityState.fromRaw(map['activityState']),
      actionKey: _readString(map['actionKey']),
      durationSec: _readInt(map['durationSec']),
      remainingSec: _readInt(map['remainingSec']),
      sessionId: _readString(map['sessionId']),
      templateId: _readString(map['templateId']),
      templateName: _readString(map['templateName']),
      updatedAtEpochMs: _readInt(map['updatedAtEpochMs']),
    );
  }

  static UserActivityStatusEntity fromRawPayload(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return UserActivityStatusEntity.fromMap(raw);
    }
    if (raw is Map) {
      return UserActivityStatusEntity.fromMap(
        raw.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }
    return UserActivityStatusEntity.idle();
  }
}

Map<String, dynamic> userActivityStatusEntityToMap(
  UserActivityStatusEntity entity,
) {
  return <String, dynamic>{
    'activityState': entity.activityState.name,
    if (entity.actionKey != null) 'actionKey': entity.actionKey,
    if (entity.durationSec != null) 'durationSec': entity.durationSec,
    if (entity.remainingSec != null) 'remainingSec': entity.remainingSec,
    if (entity.sessionId != null) 'sessionId': entity.sessionId,
    if (entity.templateId != null) 'templateId': entity.templateId,
    if (entity.templateName != null) 'templateName': entity.templateName,
    if (entity.updatedAtEpochMs != null) 'updatedAtEpochMs': entity.updatedAtEpochMs,
  };
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

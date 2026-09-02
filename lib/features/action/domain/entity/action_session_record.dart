// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认
// Firestore 文档: users/{uid}/sessions/{sessionId}(只追加的运动打卡日志)
// 本期只写 completed;'aborted' 等状态留作枚举扩展。
import 'package:freezed_annotation/freezed_annotation.dart';

part 'action_session_record.freezed.dart';

abstract class ActionSessionRecordStatus {
  static const completed = 'completed';
}

@freezed
abstract class ActionSessionRecord with _$ActionSessionRecord {
  const ActionSessionRecord._();

  const factory ActionSessionRecord({
    required String sessionId,
    required String roomId,
    required String userId,
    required String templateId,
    required String templateName,
    required String actionKey,
    required int durationSec,
    required DateTime startedAt,
    required DateTime completedAt,
    @Default(ActionSessionRecordStatus.completed) String status,
  }) = _ActionSessionRecord;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'roomId': roomId,
      'userId': userId,
      'templateId': templateId,
      'templateName': templateName,
      'actionKey': actionKey,
      'durationSec': durationSec,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'status': status,
    };
  }

  factory ActionSessionRecord.fromMap(Map<String, dynamic> source) {
    return ActionSessionRecord(
      sessionId: (source['sessionId'] ?? '').toString(),
      roomId: (source['roomId'] ?? '').toString(),
      userId: (source['userId'] ?? '').toString(),
      templateId: (source['templateId'] ?? '').toString(),
      templateName: (source['templateName'] ?? '').toString(),
      actionKey: (source['actionKey'] ?? '').toString(),
      durationSec: _asInt(source['durationSec']),
      startedAt: _asDateTime(source['startedAt']) ?? DateTime.now(),
      completedAt: _asDateTime(source['completedAt']) ?? DateTime.now(),
      status:
          (source['status'] ?? ActionSessionRecordStatus.completed).toString(),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    final dynamic maybeDate = (value as dynamic).toDate?.call();
    if (maybeDate is DateTime) {
      return maybeDate.toLocal();
    }
    return null;
  }
}

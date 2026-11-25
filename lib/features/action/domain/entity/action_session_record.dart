// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认
// Firestore 文档: users/{uid}/sessions/{sessionId}(只追加的运动打卡日志)
// 本期只写 completed;'aborted' 等状态留作枚举扩展。
import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_amount.dart';

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

    /// 做过哪个动作(P2,可选;rules 放行可选键)。
    String? motionId,

    /// 完成那一刻卡上的强度标签与量的副本(add-card-prescription,可选)。
    /// 之后卡被改或被删,记录仍然看得到当时做了什么。
    String? intensityLabel,
    @Default(<CardAmount>[]) List<CardAmount> amounts,
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
      if (motionId != null) 'motionId': motionId,
      if (intensityLabel != null && intensityLabel!.isNotEmpty)
        'intensityLabel': intensityLabel,
      if (amounts.isNotEmpty)
        'amounts': [for (final amount in amounts) amount.toMap()],
    };
  }

  /// 「中等 · 15 个 · 5 kg」;都没有返回空串。
  String get prescriptionText => [
    if (intensityLabel != null && intensityLabel!.isNotEmpty) intensityLabel!,
    for (final amount in amounts) amount.text,
  ].join(' · ');

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
      motionId: (source['motionId']?.toString().trim().isEmpty ?? true)
          ? null
          : source['motionId'].toString().trim(),
      intensityLabel: source['intensityLabel'] is String &&
              (source['intensityLabel'] as String).isNotEmpty
          ? source['intensityLabel'] as String
          : null,
      amounts: CardAmount.listFrom(source['amounts']),
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

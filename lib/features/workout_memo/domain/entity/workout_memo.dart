// Firestore 文档: users/{uid}/session_memos/{sessionId}(与运动记录分开保存,可改可删)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_memo.freezed.dart';

/// 一次运动的 memo:感受、一句话,全部可选(design.md §1)。
/// 做了多少(次数 / 距离 / 重量)不在这里——那是卡片自带的信息,不是事后填的。
@freezed
abstract class WorkoutMemo with _$WorkoutMemo {
  const WorkoutMemo._();

  const factory WorkoutMemo({
    /// 运动记录的 id,也是文档 id。
    required String sessionId,
    required String templateId,

    /// 抄自运动记录的完成时间(按时间取最近的 memo 用)。
    required DateTime completedAt,
    required DateTime updatedAt,

    /// 感受档位的 key(文案在配置里)。
    String? feel,
    String? note,
  }) = _WorkoutMemo;

  /// 没有任何内容:不保存这样的 memo(保存时改为删除)。
  bool get isEmpty => feel == null && (note == null || note!.trim().isEmpty);

  Map<String, dynamic> toMap() {
    final text = note?.trim();
    return {
      'sessionId': sessionId,
      'templateId': templateId,
      'completedAt': completedAt,
      'updatedAt': updatedAt,
      if (feel != null) 'feel': feel,
      if (text != null && text.isNotEmpty) 'note': text,
    };
  }

  /// 解析不了(缺必填字段)返回 null。
  static WorkoutMemo? fromMap(Map<String, dynamic> source) {
    final sessionId = source['sessionId']?.toString() ?? '';
    final completedAt = _asDateTime(source['completedAt']);
    if (sessionId.isEmpty || completedAt == null) {
      return null;
    }
    final feel = source['feel'];
    final note = source['note'];
    return WorkoutMemo(
      sessionId: sessionId,
      templateId: source['templateId']?.toString() ?? '',
      completedAt: completedAt,
      updatedAt: _asDateTime(source['updatedAt']) ?? completedAt,
      feel: feel is String && feel.isNotEmpty ? feel : null,
      note: note is String && note.trim().isNotEmpty ? note.trim() : null,
    );
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
    return maybeDate is DateTime ? maybeDate.toLocal() : null;
  }
}

import '../../action/domain/entity/action_session_record.dart';

/// 把最近的运动记录压成发给模型的上下文文本。
///
/// 只带对回答有用的字段(时间、卡名、动作、时长),不带 uid / roomId /
/// sessionId。今天的日期一并给出,便于回答「本周」「昨天」类问题。
class BuildCoachContextUsecase {
  const BuildCoachContextUsecase();

  /// 与运动历史页同一批记录的上限。
  static const maxRecords = 100;

  String execute(List<ActionSessionRecord> records, {required DateTime now}) {
    final buffer = StringBuffer()
      ..writeln('Today: ${_date(now)} (${_weekday(now)})')
      ..writeln(
        "The user's most recent workout records (newest first, at most "
        '$maxRecords). Columns: completedAt | card name | action key | '
        'duration seconds.',
      );
    if (records.isEmpty) {
      buffer.writeln('(none — the user has not completed any workout yet)');
      return buffer.toString();
    }
    for (final ActionSessionRecord record in records.take(maxRecords)) {
      final DateTime at = record.completedAt.toLocal();
      buffer.writeln(
        '${_date(at)} ${_two(at.hour)}:${_two(at.minute)} | '
        '${record.templateName} | ${record.actionKey} | ${record.durationSec}',
      );
    }
    return buffer.toString();
  }

  static String _date(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _weekday(DateTime t) => _weekdays[t.weekday - 1];
}

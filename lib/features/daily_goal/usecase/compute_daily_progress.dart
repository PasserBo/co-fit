import '../../action/domain/entity/action_session_record.dart';
import '../domain/daily_progress_metric.dart';
import '../domain/entity/daily_progress.dart';

/// 今日进度(纯函数,design.md §1、§3):只统计完成时间落在 [day] 这个
/// 本地日历日里的记录,用 [metric] 计量后与 [target] 比较。
DailyProgress computeDailyProgress({
  required List<ActionSessionRecord> records,
  required DateTime day,
  required DailyProgressMetric metric,
  required int target,
}) {
  final todays = [
    for (final record in records)
      if (_sameDay(record.completedAt.toLocal(), day)) record,
  ];
  return DailyProgress(
    current: metric.measure(todays),
    target: target,
    unit: metric.unit,
  );
}

/// [time] 所在的本地日历日(零点)。
DateTime localDayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

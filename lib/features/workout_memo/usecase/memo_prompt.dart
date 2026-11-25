import '../../action/domain/entity/action_session_record.dart';

/// 今日面板「刚才这张」针对哪条记录(纯函数,design.md §4):
/// 最新完成的一条,且完成时间在可补记的时长之内;否则没有。
ActionSessionRecord? memoPromptTarget({
  required List<ActionSessionRecord> records,
  required DateTime now,
  required Duration window,
}) {
  ActionSessionRecord? latest;
  for (final record in records) {
    if (latest == null || record.completedAt.isAfter(latest.completedAt)) {
      latest = record;
    }
  }
  if (latest == null || window <= Duration.zero) {
    return null;
  }
  final age = now.difference(latest.completedAt);
  return age < window ? latest : null;
}

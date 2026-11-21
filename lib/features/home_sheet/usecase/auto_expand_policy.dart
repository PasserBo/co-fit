import '../domain/entity/home_sheet_layout.dart';

/// 触发「是否自动展开今日面板」判断的时机。
enum AutoExpandTrigger { coldStart, resumed, completed }

/// 自动展开规则(design.md §13,纯函数):其他情况保持用户上次留下的状态。
abstract final class AutoExpandPolicy {
  static bool shouldExpand({
    required AutoExpandTrigger trigger,
    required HomeSheetLayout layout,
    required DateTime now,
    DateTime? leftAt,
  }) {
    if (!layout.enabled) {
      return false;
    }
    switch (trigger) {
      case AutoExpandTrigger.coldStart:
        return layout.expandOnColdStart;
      case AutoExpandTrigger.completed:
        return layout.expandAfterCompletion;
      case AutoExpandTrigger.resumed:
        final minutes = layout.expandAfterAwayMinutes;
        if (minutes == null || leftAt == null) {
          return false;
        }
        return now.difference(leftAt) >= Duration(minutes: minutes);
    }
  }
}

/// 没被看到的完成(「欠的庆祝」)的判定(纯函数)。
abstract final class PendingCelebrationPolicy {
  /// 回到房间页时是否补播:有欠的、且最近一次完成没超过有效期。
  static bool shouldReplay({
    required int pendingCount,
    required DateTime? lastCompletedAt,
    required DateTime now,
    required HomeSheetLayout layout,
  }) {
    if (!layout.enabled || pendingCount <= 0 || lastCompletedAt == null) {
      return false;
    }
    return now.difference(lastCompletedAt) <=
        Duration(hours: layout.celebrationMaxAgeHours);
  }
}

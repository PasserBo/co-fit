/// 用户自己选的今日目标(design.md §4:只存本机)。
/// 按用户与计量方式分开保存——换计量方式时旧目标不会被套用。
abstract interface class DailyGoalRepository {
  /// 没存过返回 null。
  Future<int?> loadTarget({required String userId, required String metricId});

  Future<void> saveTarget({
    required String userId,
    required String metricId,
    required int target,
  });
}

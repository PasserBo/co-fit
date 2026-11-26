/// 使用数据统计的出口(change add-usage-analytics)。
///
/// - 只记事件与少量参数;**不上报用户 id、不收集广告标识符**,统计不与账号关联。
/// - 事件名与参数集中在 [AnalyticsEvents],改名会断开历史数据,只加不改。
/// - 记录失败绝不影响功能:实现里吞掉异常。
abstract interface class AnalyticsTracker {
  Future<void> log(String name, [Map<String, Object> params = const {}]);
}

/// 测试与 Firebase 未初始化时用。
class NoopAnalyticsTracker implements AnalyticsTracker {
  const NoopAnalyticsTracker();

  @override
  Future<void> log(
    String name, [
    Map<String, Object> params = const {},
  ]) async {}
}

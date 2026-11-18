/// 「登录前演示房间已看过」的设备级标记。
///
/// 只有两个动作:读、置为已看过;没有「清除」——规格规定演示在一台设备上
/// 只出现一次,重装 App 才会再见到。实现:
/// data/shared_preferences_welcome_tour_seen_repository.dart(线上)、
/// data/in_memory_welcome_tour_seen_repository.dart(测试)。
abstract class WelcomeTourSeenRepository {
  Future<bool> isSeen();
  Future<void> markSeen();
}

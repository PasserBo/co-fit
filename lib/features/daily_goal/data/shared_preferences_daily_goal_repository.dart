import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_goal_repository.dart';

/// 每个「用户 + 计量方式」一个键。
class SharedPreferencesDailyGoalRepository implements DailyGoalRepository {
  static String _key(String userId, String metricId) =>
      'cofit.daily_goal.v1.$userId.$metricId';

  @override
  Future<int?> loadTarget({
    required String userId,
    required String metricId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_key(userId, metricId));
    return value != null && value >= 1 ? value : null;
  }

  @override
  Future<void> saveTarget({
    required String userId,
    required String metricId,
    required int target,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(userId, metricId), target);
  }
}

import '../domain/daily_goal_repository.dart';

/// 测试用。
class InMemoryDailyGoalRepository implements DailyGoalRepository {
  final Map<String, int> _targets = {};

  @override
  Future<int?> loadTarget({
    required String userId,
    required String metricId,
  }) async => _targets['$userId.$metricId'];

  @override
  Future<void> saveTarget({
    required String userId,
    required String metricId,
    required int target,
  }) async {
    _targets['$userId.$metricId'] = target;
  }
}

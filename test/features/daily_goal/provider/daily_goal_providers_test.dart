import 'package:cofit/core/flags/feature_flags.dart';
import 'package:cofit/core/flags/feature_flags_provider.dart';
import 'package:cofit/features/action/provider/action_session_history_providers.dart';
import 'package:cofit/features/daily_goal/data/in_memory_daily_goal_repository.dart';
import 'package:cofit/features/daily_goal/provider/daily_goal_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late InMemoryDailyGoalRepository repository;

  ProviderContainer container({String userId = 'me', String config = ''}) {
    final c = ProviderContainer(
      overrides: [
        featureFlagsProvider.overrideWith(
          (ref) async => FeatureFlags(dailyGoalConfig: config),
        ),
        dailyGoalUserIdProvider.overrideWithValue(userId),
        dailyGoalRepositoryProvider.overrideWithValue(repository),
        dailyGoalClockProvider.overrideWithValue(() => now),
        recentSessionsProvider.overrideWith(
          (ref) async => [
            record(DateTime(2026, 11, 25, 9)),
            record(DateTime(2026, 11, 25, 10)),
            record(DateTime(2026, 11, 24, 10)),
          ],
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    now = DateTime(2026, 11, 25, 12);
    repository = InMemoryDailyGoalRepository();
  });

  test('没存过目标:用默认值', () async {
    final c = container();
    await c.read(savedDailyTargetProvider.future);
    await c.read(recentSessionsProvider.future);
    expect(c.read(dailyTargetProvider), 2);
    final progress = c.read(dailyProgressProvider).value!;
    expect(progress.current, 2);
    expect(progress.reached, isTrue);
  });

  test('改目标:立即生效并保存,下次还在', () async {
    final c = container();
    await c.read(savedDailyTargetProvider.future);
    await c.read(recentSessionsProvider.future);
    await c.read(savedDailyTargetProvider.notifier).setTarget(3);
    expect(c.read(dailyTargetProvider), 3);
    expect(c.read(dailyProgressProvider).value!.reached, isFalse);

    final again = container();
    expect(await again.read(savedDailyTargetProvider.future), 3);
  });

  test('目标按用户分开保存', () async {
    final c = container();
    await c.read(savedDailyTargetProvider.future);
    await c.read(savedDailyTargetProvider.notifier).setTarget(5);

    final other = container(userId: 'someone-else');
    expect(await other.read(savedDailyTargetProvider.future), isNull);
    expect(other.read(dailyTargetProvider), 2);
  });

  test('目标按计量方式分开保存', () async {
    final c = container();
    await c.read(savedDailyTargetProvider.future);
    await c.read(savedDailyTargetProvider.notifier).setTarget(5);

    final minutes = container(
      config: '{"metric":"minutes","defaultTarget":10}',
    );
    await minutes.read(featureFlagsProvider.future);
    expect(await minutes.read(savedDailyTargetProvider.future), isNull);
    expect(minutes.read(dailyTargetProvider), 10);
  });

  test('可选目标里总是包含用户当前的目标', () async {
    final c = container();
    await c.read(savedDailyTargetProvider.future);
    await c.read(savedDailyTargetProvider.notifier).setTarget(4);
    expect(c.read(dailyTargetChoicesProvider), [1, 2, 3, 4, 5, 8]);
  });

  test('过了零点:进度归零,目标不变', () async {
    final c = container();
    await c.read(savedDailyTargetProvider.future);
    await c.read(recentSessionsProvider.future);
    expect(c.read(dailyProgressProvider).value!.current, 2);

    now = DateTime(2026, 11, 26, 0, 0, 1);
    c.read(currentDayProvider.notifier).refresh();
    final progress = c.read(dailyProgressProvider).value!;
    expect(progress.current, 0);
    expect(progress.target, 2);
  });
}

import 'package:cofit/core/flags/feature_flags.dart';
import 'package:cofit/core/flags/feature_flags_provider.dart';
import 'package:cofit/core/theme/cofit_dimens.dart';
import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/presentation/widget/workout_history_body.dart';
import 'package:cofit/features/action/provider/action_session_history_providers.dart';
import 'package:cofit/features/daily_goal/data/in_memory_daily_goal_repository.dart';
import 'package:cofit/features/daily_goal/presentation/view/daily_progress_history_header_view.dart';
import 'package:cofit/features/daily_goal/presentation/view/daily_progress_module_view.dart';
import 'package:cofit/features/daily_goal/presentation/widget/progress_ring.dart';
import 'package:cofit/features/daily_goal/provider/daily_goal_providers.dart';
import 'package:cofit/features/home_sheet/domain/entity/home_sheet_layout.dart';
import 'package:cofit/features/home_sheet/presentation/module/home_sheet_module.dart';
import 'package:cofit/features/home_sheet/provider/home_sheet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

const _card = ActionTemplateCard(
  id: 'squat',
  name: '深蹲',
  type: ActionType.strength,
  rawType: 'strength',
  source: ActionSource.official,
  ablyActionId: 'squat',
  defaultDurationSec: 90,
  intensityBaseline: {},
);

class _FakeHost implements HomeSheetHost {
  final calls = <String>[];

  @override
  void collapseSheet() => calls.add('collapse');

  @override
  final ValueNotifier<int> celebrations = ValueNotifier(0);

  @override
  Duration celebrationDelay(String moduleId) => Duration.zero;

  @override
  bool focusFanOnCard(String cardId) {
    calls.add('focus:$cardId');
    return true;
  }
}

/// 可在测试里改的运动记录。
class _Records extends Notifier<List<ActionSessionRecord>> {
  _Records(this._initial);
  final List<ActionSessionRecord> _initial;

  @override
  List<ActionSessionRecord> build() => _initial;

  void add(ActionSessionRecord r) => state = [r, ...state];
}

final _day = DateTime(2026, 11, 25);
ActionSessionRecord _today(int hour) => record(DateTime(2026, 11, 25, hour));

late NotifierProvider<_Records, List<ActionSessionRecord>> _records;
late DateTime _now;

/// 让零延迟的定时器触发(pump() 不带时长不会推进时间)。
const _tick = Duration(milliseconds: 1);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(_tick);
  }
}

Future<(ProviderContainer, _FakeHost)> _pump(
  WidgetTester tester, {
  List<ActionSessionRecord> records = const [],
  ActionTemplateCard? recommended = _card,
  bool reduceMotion = false,
  bool failed = false,
  Widget? child,
}) async {
  _now = _day.add(const Duration(hours: 12));
  _records = NotifierProvider(() => _Records(records));
  final host = _FakeHost();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWith((ref) async => FeatureFlags.defaults),
        dailyGoalUserIdProvider.overrideWithValue('me'),
        dailyGoalRepositoryProvider.overrideWithValue(
          InMemoryDailyGoalRepository(),
        ),
        dailyGoalClockProvider.overrideWithValue(() => _now),
        recentSessionsProvider.overrideWith((ref) async {
          if (failed) {
            throw StateError('offline');
          }
          return ref.watch(_records);
        }),
        recommendedCardProvider.overrideWithValue(recommended),
      ],
      child: MaterialApp(
        theme: CoFitTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: child ?? DailyProgressModuleView(host: host)),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  return (container, host);
}

String _value(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('daily_progress_value')))
    .data!;
String _hint(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('daily_progress_hint')))
    .data!;
double _ring(WidgetTester tester) =>
    tester.widget<ProgressRing>(find.byType(ProgressRing)).fraction;

void main() {
  testWidgets('今天做了一部分:1 / 2,进度环一半,提示还差 1', (tester) async {
    await _pump(tester, records: [_today(9)]);
    expect(_value(tester), '1 / 2 张');
    expect(_ring(tester), 0.5);
    expect(_hint(tester), '还差 1 张');
  });

  testWidgets('已达成:进度环闭合,数字照实显示', (tester) async {
    await _pump(tester, records: [_today(8), _today(9), _today(10)]);
    expect(_value(tester), '3 / 2 张');
    expect(_ring(tester), 1);
    expect(_hint(tester), '今日目标已达成');
  });

  testWidgets('记录加载失败:模块不出现', (tester) async {
    await _pump(tester, failed: true);
    expect(
      find.byKey(const ValueKey('home_sheet_daily_progress')),
      findsNothing,
    );
  });

  testWidgets('今天还没开始:提示从今日推荐开始,点它 = 点今日推荐', (tester) async {
    final (_, host) = await _pump(tester);
    expect(_value(tester), '0 / 2 张');
    expect(_hint(tester), '从今日推荐开始');

    await tester.tap(find.byKey(const ValueKey('daily_progress_value')));
    expect(host.calls, ['focus:squat', 'collapse']);
  });

  testWidgets('今天还没开始且没有可推荐的卡:只显示 0 / 目标,点了没反应', (tester) async {
    final (_, host) = await _pump(tester, recommended: null);
    expect(_value(tester), '0 / 2 张');
    expect(_hint(tester), '还差 2 张');

    await tester.tap(find.byKey(const ValueKey('daily_progress_value')));
    expect(host.calls, isEmpty);
  });

  testWidgets('完成一次:等庆祝节拍到了才从旧值变到新值', (tester) async {
    final (container, host) = await _pump(tester);

    container.read(_records.notifier).add(_today(11));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_value(tester), '0 / 2 张'); // 节拍还没到

    host.celebrations.value++;
    await tester.pump(_tick);
    await tester.pump();
    expect(_value(tester), '1 / 2 张');
    await tester.pumpAndSettle();
    expect(_ring(tester), 0.5);
  });

  testWidgets('节拍先于新记录到达:记录一到就更新', (tester) async {
    final (container, host) = await _pump(tester);

    host.celebrations.value++;
    await tester.pump(const Duration(milliseconds: 200));
    container.read(_records.notifier).add(_today(11));
    await _settle(tester);
    expect(_value(tester), '1 / 2 张');
    await tester.pumpAndSettle();
  });

  testWidgets('没有播放庆祝:短暂等待后直接更新', (tester) async {
    final (container, _) = await _pump(tester);

    container.read(_records.notifier).add(_today(11));
    await tester.pump();
    await tester.pump(CoFitMotion.dailyProgressBeatTimeout ~/ 2);
    expect(_value(tester), '0 / 2 张');
    await tester.pump(CoFitMotion.dailyProgressBeatTimeout);
    await tester.pump();
    expect(_value(tester), '1 / 2 张');
    await tester.pumpAndSettle();
  });

  group('达成反馈', () {
    late List<String> haptics;
    setUp(() {
      haptics = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<void> complete(
      WidgetTester tester,
      ProviderContainer container,
      _FakeHost host,
      int hour,
    ) async {
      container.read(_records.notifier).add(_today(hour));
      await tester.pump();
      host.celebrations.value++;
      await tester.pump(_tick);
      await tester.pumpAndSettle();
    }

    testWidgets('达成的那一次播一次;之后继续运动不再播', (tester) async {
      final (container, host) = await _pump(tester, records: [_today(9)]);

      await complete(tester, container, host, 11);
      expect(_value(tester), '2 / 2 张');
      expect(_hint(tester), '今日目标已达成');
      expect(haptics, ['HapticFeedbackType.heavyImpact']);

      await complete(tester, container, host, 12);
      expect(_value(tester), '3 / 2 张');
      expect(haptics.length, 1);
    });

    testWidgets('尚未达成的一次不播', (tester) async {
      final (container, host) = await _pump(tester);
      await complete(tester, container, host, 11);
      expect(_value(tester), '1 / 2 张');
      expect(haptics, isEmpty);
    });

    testWidgets('把目标调低到已完成的数量:环闭合但不播达成反馈', (tester) async {
      final (container, _) = await _pump(tester, records: [_today(9)]);
      await container.read(savedDailyTargetProvider.notifier).setTarget(1);
      await tester.pumpAndSettle();
      expect(_value(tester), '1 / 1 张');
      expect(_ring(tester), 1);
      expect(haptics, isEmpty);
    });
  });

  testWidgets('调整目标:选 3 后立即生效', (tester) async {
    await _pump(tester, records: [_today(9), _today(10)]);
    expect(_hint(tester), '今日目标已达成');

    await tester.tap(find.byKey(const ValueKey('daily_progress_edit_target')));
    await tester.pumpAndSettle();
    expect(find.text('今日目标'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('daily_target_3')));
    await tester.pumpAndSettle();

    expect(_value(tester), '2 / 3 张');
    expect(_hint(tester), '还差 1 张');
    expect(_ring(tester), closeTo(2 / 3, 0.001));
  });

  testWidgets('App 开着过零点:进度归零,目标不变', (tester) async {
    final (container, _) = await _pump(
      tester,
      records: [_today(9), _today(10)],
    );
    expect(_value(tester), '2 / 2 张');

    _now = DateTime(2026, 11, 26, 0, 0, 1);
    container.read(currentDayProvider.notifier).refresh();
    await tester.pump();
    expect(_value(tester), '0 / 2 张');
    expect(_ring(tester), 0);
  });

  testWidgets('减弱动态效果:直接变到新值,不播过渡', (tester) async {
    final (container, host) = await _pump(tester, reduceMotion: true);
    container.read(_records.notifier).add(_today(11));
    await _settle(tester);
    host.celebrations.value++;
    await _settle(tester);
    expect(_value(tester), '1 / 2 张');
    expect(_ring(tester), 0.5); // 没有中间帧
  });

  testWidgets('运动历史页顶部显示同样的今日进度', (tester) async {
    final records = [_today(9)];
    await _pump(
      tester,
      records: records,
      child: WorkoutHistoryBody(
        records: records,
        now: _day.add(const Duration(hours: 12)),
        header: const DailyProgressHistoryHeaderView(),
      ),
    );
    expect(
      find.byKey(const ValueKey('history_daily_progress')),
      findsOneWidget,
    );
    expect(_value(tester), '1 / 2 张');
    expect(_ring(tester), 0.5);
  });

  test('内置默认布局:今日进度排在今日推荐之前,且已登记', () {
    final modules = HomeSheetLayout.defaults.modules;
    expect(
      modules.indexOf(HomeSheetModuleIds.dailyProgress),
      lessThan(modules.indexOf(HomeSheetModuleIds.recommendation)),
    );
    expect(
      resolveHomeSheetModules(HomeSheetLayout.defaults).map((s) => s.id),
      HomeSheetLayout.defaults.modules,
    );
  });
}

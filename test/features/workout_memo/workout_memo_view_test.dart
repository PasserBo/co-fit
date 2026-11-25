import 'package:cofit/core/flags/feature_flags.dart';
import 'package:cofit/core/flags/feature_flags_provider.dart';
import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/presentation/view/workout_history_page_view.dart';
import 'package:cofit/features/action/provider/action_session_history_providers.dart';
import 'package:cofit/features/ai_coach/provider/ai_coach_providers.dart';
import 'package:cofit/features/daily_goal/data/in_memory_daily_goal_repository.dart';
import 'package:cofit/features/daily_goal/presentation/view/daily_progress_module_view.dart';
import 'package:cofit/features/daily_goal/provider/daily_goal_providers.dart';
import 'package:cofit/features/home_sheet/domain/entity/home_sheet_layout.dart';
import 'package:cofit/features/home_sheet/presentation/module/home_sheet_module.dart';
import 'package:cofit/features/home_sheet/provider/home_sheet_providers.dart';
import 'package:cofit/features/workout_memo/data/in_memory_workout_memo_repository.dart';
import 'package:cofit/features/workout_memo/domain/entity/workout_memo.dart';
import 'package:cofit/features/workout_memo/presentation/view/last_session_memo_module_view.dart';
import 'package:cofit/features/workout_memo/provider/workout_memo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

class _Records extends Notifier<List<ActionSessionRecord>> {
  _Records(this._initial);
  final List<ActionSessionRecord> _initial;

  @override
  List<ActionSessionRecord> build() => _initial;

  void add(ActionSessionRecord r) => state = [r, ...state];
}

class _Host implements HomeSheetHost {
  final calls = <String>[];

  @override
  final ValueNotifier<int> celebrations = ValueNotifier(0);

  @override
  Duration celebrationDelay(String moduleId) => Duration.zero;

  @override
  void collapseSheet() => calls.add('collapse');

  @override
  bool focusFanOnCard(String cardId) => true;
}

final _noon = DateTime(2026, 11, 25, 12);
late DateTime _now;
late InMemoryWorkoutMemoRepository _repository;
late NotifierProvider<_Records, List<ActionSessionRecord>> _records;

const _tick = Duration(milliseconds: 1);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(_tick);
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget child, {
  List<ActionSessionRecord> records = const [],
}) async {
  _now = _noon;
  _records = NotifierProvider(() => _Records(records));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWith((ref) async => FeatureFlags.defaults),
        aiCoachEntryVisibleProvider.overrideWithValue(false),
        recommendedCardProvider.overrideWithValue(null),
        dailyGoalUserIdProvider.overrideWithValue('me'),
        dailyGoalRepositoryProvider.overrideWithValue(
          InMemoryDailyGoalRepository(),
        ),
        dailyGoalClockProvider.overrideWithValue(() => _now),
        workoutMemoUserIdProvider.overrideWithValue('me'),
        workoutMemoRepositoryProvider.overrideWithValue(_repository),
        workoutMemoClockProvider.overrideWithValue(() => _now),
        recentSessionsProvider.overrideWith((ref) async => ref.watch(_records)),
      ],
      child: MaterialApp(
        theme: CoFitTheme.dark,
        home: Scaffold(body: child),
      ),
    ),
  );
  await _settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Finder _feel(String key) => find.byKey(ValueKey('memo_feel_$key'));
const _module = ValueKey('home_sheet_last_session_memo');

WorkoutMemo? _saved(String sessionId) => _repository.of('me')[sessionId];

void main() {
  setUp(() => _repository = InMemoryWorkoutMemoRepository());

  final justNow = record(_noon.subtract(const Duration(minutes: 2)), id: 's1');

  group('今日面板「刚才这张」', () {
    testWidgets('刚做完:显示卡名和三个感受档位', (tester) async {
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      expect(find.byKey(_module), findsOneWidget);
      expect(find.textContaining('深蹲', findRichText: true), findsOneWidget);
      expect(find.text('😌 轻松'), findsOneWidget);
      expect(find.text('🙂 刚好'), findsOneWidget);
      expect(find.text('😮‍💨 吃力'), findsOneWidget);
      expect(_saved('s1'), isNull); // 什么都不点 = 不写
    });

    testWidgets('最近一次已超过可补记的时长:不出现', (tester) async {
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [record(_noon.subtract(const Duration(minutes: 31)))],
      );
      expect(find.byKey(_module), findsNothing);
    });

    testWidgets('点一个档位立即保存;改选;再点一次取消', (tester) async {
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );

      await tester.tap(_feel('ok'));
      await _settle(tester);
      expect(_saved('s1')!.feel, 'ok');
      expect(_saved('s1')!.templateId, 'squat');

      await tester.tap(_feel('hard'));
      await _settle(tester);
      expect(_saved('s1')!.feel, 'hard');

      await tester.tap(_feel('hard'));
      await _settle(tester);
      expect(_saved('s1'), isNull); // 没有别的内容 → memo 不再存在
    });

    testWidgets('保存失败:选中状态回到之前,并提示', (tester) async {
      final container = await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      _repository.failWrites = true;

      await tester.tap(_feel('ok'));
      await _settle(tester);
      expect(container.read(workoutMemoMapProvider), isEmpty);
      expect(find.text('没有保存成功,请稍后再试'), findsOneWidget);
    });

    testWidgets('不问次数:任何卡都没有次数一栏', (tester) async {
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      expect(find.text('次数'), findsNothing);
      expect(find.byKey(const ValueKey('memo_note')), findsOneWidget);
    });

    testWidgets('写一句:保存后模块里显示这句话', (tester) async {
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      await tester.tap(find.byKey(const ValueKey('memo_note')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '腿还酸');
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(_saved('s1')!.note, '腿还酸');
      expect(find.text('腿还酸'), findsOneWidget);
    });

    testWidgets('连续做了两张:改为针对最新的那一张', (tester) async {
      final container = await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      _now = _noon.add(const Duration(minutes: 1));
      container
          .read(_records.notifier)
          .add(
            record(
              _noon.add(const Duration(seconds: 50)),
              id: 's2',
              name: '俯卧撑',
            ),
          );
      await _settle(tester);
      expect(find.textContaining('俯卧撑', findRichText: true), findsOneWidget);

      await tester.tap(_feel('easy'));
      await _settle(tester);
      expect(_saved('s2')!.feel, 'easy');
      expect(_saved('s1'), isNull);
    });

    testWidgets('已经记过:回来时显示已选中的内容(离开再回来)', (tester) async {
      await _repository.save(
        userId: 'me',
        memo: WorkoutMemo(
          sessionId: 's1',
          templateId: 'squat',
          completedAt: justNow.completedAt,
          updatedAt: _noon,
          feel: 'ok',
          note: '之前写的',
        ),
      );
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      expect(find.text('之前写的'), findsOneWidget);
      // 再点已选中的「刚好」只清掉感受,文字还在
      await tester.tap(_feel('ok'));
      await _settle(tester);
      expect(_saved('s1')!.feel, isNull);
      expect(_saved('s1')!.note, '之前写的');
    });

    testWidgets('App 开着超过时长:模块消失', (tester) async {
      await _pump(
        tester,
        const LastSessionMemoModuleView(),
        records: [justNow],
      );
      expect(find.byKey(_module), findsOneWidget);

      _now = _noon.add(const Duration(minutes: 29));
      await tester.pump(const Duration(minutes: 29));
      await _settle(tester);
      expect(find.byKey(_module), findsNothing);
    });
  });

  group('运动历史', () {
    final old = record(DateTime(2026, 11, 22, 9), id: 'old', name: '平板支撑');

    testWidgets('行里露出 memo;没有 memo 的保持原样', (tester) async {
      await _repository.save(
        userId: 'me',
        memo: WorkoutMemo(
          sessionId: 's1',
          templateId: 'squat',
          completedAt: justNow.completedAt,
          updatedAt: _noon,
          feel: 'hard',
          note: '腿还酸',
        ),
      );
      await _pump(
        tester,
        const WorkoutHistoryPageView(),
        records: [justNow, old],
      );
      expect(find.text('😮‍💨 吃力 · 腿还酸'), findsOneWidget);
      expect(find.textContaining('轻松'), findsNothing);
    });

    testWidgets('memo 加载失败:记录照常显示', (tester) async {
      _repository.failReads = true;
      await _pump(
        tester,
        const WorkoutHistoryPageView(),
        records: [justNow, old],
      );
      expect(find.text('平板支撑'), findsOneWidget);
      expect(find.text('深蹲'), findsOneWidget);
    });

    testWidgets('点开以前的记录补记;回到列表后这一行显示', (tester) async {
      await _pump(
        tester,
        const WorkoutHistoryPageView(),
        records: [justNow, old],
      );
      await tester.tap(find.byKey(const ValueKey('history_record_old')));
      await tester.pumpAndSettle();
      await tester.tap(_feel('easy'));
      await _settle(tester);
      expect(_saved('old')!.feel, 'easy');

      await tester.tapAt(const Offset(20, 20)); // 点遮罩关闭
      await tester.pumpAndSettle();
      expect(find.text('😌 轻松'), findsOneWidget);
    });

    testWidgets('删除 memo:记录还在,行里不再显示', (tester) async {
      await _repository.save(
        userId: 'me',
        memo: WorkoutMemo(
          sessionId: 'old',
          templateId: 'squat',
          completedAt: old.completedAt,
          updatedAt: _noon,
          note: '只有一句话',
        ),
      );
      await _pump(
        tester,
        const WorkoutHistoryPageView(),
        records: [justNow, old],
      );
      await tester.tap(find.byKey(const ValueKey('history_record_old')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('memo_sheet_full_note')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('memo_sheet_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(_saved('old'), isNull);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('只有一句话'), findsNothing);
      expect(find.text('平板支撑'), findsOneWidget);
    });
  });

  group('今日进度直达运动历史', () {
    testWidgets('今天做过:点今日进度打开运动历史页', (tester) async {
      await _pump(
        tester,
        DailyProgressModuleView(host: _Host()),
        records: [justNow],
      );
      await tester.tap(find.byKey(const ValueKey('daily_progress_value')));
      await tester.pumpAndSettle();
      expect(find.text('运动历史'), findsOneWidget);
    });

    testWidgets('今天还没做:不打开运动历史页', (tester) async {
      await _pump(tester, DailyProgressModuleView(host: _Host()));
      await tester.tap(find.byKey(const ValueKey('daily_progress_value')));
      await tester.pumpAndSettle();
      expect(find.text('运动历史'), findsNothing);
    });
  });

  test('内置默认布局:刚才这张排在最前,且已登记', () {
    expect(HomeSheetLayout.defaults.modules.first, 'last_session_memo');
    expect(
      resolveHomeSheetModules(HomeSheetLayout.defaults).map((s) => s.id),
      HomeSheetLayout.defaults.modules,
    );
  });
}

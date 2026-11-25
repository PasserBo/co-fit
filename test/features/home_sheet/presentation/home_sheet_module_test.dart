import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/provider/action_decks_provider.dart';
import 'package:cofit/features/home_sheet/domain/entity/home_sheet_layout.dart';
import 'package:cofit/features/home_sheet/presentation/module/home_sheet_module.dart';
import 'package:cofit/features/home_sheet/presentation/view/recommendation_module_view.dart';
import 'package:cofit/features/home_sheet/presentation/widget/home_sheet_panel.dart';
import 'package:cofit/features/home_sheet/provider/home_sheet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  bool focusResult = true;

  @override
  void collapseSheet() => calls.add('collapse');

  @override
  final ValueNotifier<int> celebrations = ValueNotifier(0);

  @override
  Duration celebrationDelay(String moduleId) => Duration.zero;

  @override
  bool focusFanOnCard(String cardId) {
    calls.add('focus:$cardId');
    return focusResult;
  }
}

HomeSheetModuleSpec _spec(String id, HomeSheetModuleStatus status) =>
    HomeSheetModuleSpec(
      id: id,
      status: Provider((ref) => status),
      build: (host) => Text('module-$id'),
    );

void main() {
  group('resolveHomeSheetModules', () {
    final registry = {
      'a': _spec('a', HomeSheetModuleStatus.content),
      'b': _spec('b', HomeSheetModuleStatus.content),
    };

    test('保持配置顺序', () {
      final specs = resolveHomeSheetModules(
        const HomeSheetLayout(modules: ['b', 'a']),
        registry: registry,
      );
      expect(specs.map((s) => s.id), ['b', 'a']);
    });

    test('跳过这个版本不认识的模块与重复的 id', () {
      final specs = resolveHomeSheetModules(
        const HomeSheetLayout(modules: ['future', 'a', 'a', 'b']),
        registry: registry,
      );
      expect(specs.map((s) => s.id), ['a', 'b']);
    });

    test('空清单 = 没有模块(面板关闭)', () {
      expect(
        resolveHomeSheetModules(
          const HomeSheetLayout(modules: []),
          registry: registry,
        ),
        isEmpty,
      );
    });

    test('内置默认布局包含今日推荐', () {
      final specs = resolveHomeSheetModules(HomeSheetLayout.defaults);
      expect(
        specs.map((s) => s.id),
        contains(HomeSheetModuleIds.recommendation),
      );
    });
  });

  group('今日推荐模块', () {
    Future<_FakeHost> pump(
      WidgetTester tester, {
      ActionTemplateCard? card,
    }) async {
      final host = _FakeHost();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recommendedCardProvider.overrideWithValue(card)],
          child: MaterialApp(
            theme: CoFitTheme.dark,
            home: Scaffold(body: RecommendationModuleView(host: host)),
          ),
        ),
      );
      return host;
    }

    testWidgets('展示推荐卡的名称、类型与时长', (tester) async {
      await pump(tester, card: _card);
      expect(find.text('今日推荐'), findsOneWidget);
      expect(find.text('深蹲'), findsOneWidget);
      expect(find.textContaining('2 分钟'), findsOneWidget);
    });

    testWidgets('点它:先让手牌停在这张卡,再收起面板', (tester) async {
      final host = await pump(tester, card: _card);
      await tester.tap(find.byKey(const ValueKey('home_sheet_recommendation')));
      expect(host.calls, ['focus:squat', 'collapse']);
    });

    testWidgets('卡已不在手牌:仍然收起面板(进入普通选卡)', (tester) async {
      final host = await pump(tester, card: _card)
        ..focusResult = false;
      await tester.tap(find.byKey(const ValueKey('home_sheet_recommendation')));
      expect(host.calls.last, 'collapse');
    });

    testWidgets('没有可推荐的卡:不画任何东西', (tester) async {
      await pump(tester);
      expect(find.byType(HomeSheetModuleFrame), findsNothing);
      expect(find.text('今日推荐'), findsNothing);
    });
  });

  group('今日推荐的状态', () {
    HomeSheetModuleStatus statusWith({
      required ActionTemplateCard? card,
      required bool loading,
    }) {
      final container = ProviderContainer(
        overrides: [
          recommendedCardProvider.overrideWithValue(card),
          activeHandLoadingProvider.overrideWithValue(loading),
        ],
      );
      addTearDown(container.dispose);
      return container.read(
        homeSheetModuleRegistry[HomeSheetModuleIds.recommendation]!.status,
      );
    }

    test('有卡 = 有内容;手牌为空 = 无内容;还在加载 = 加载中', () {
      expect(
        statusWith(card: _card, loading: false),
        HomeSheetModuleStatus.content,
      );
      expect(
        statusWith(card: null, loading: false),
        HomeSheetModuleStatus.empty,
      );
      expect(
        statusWith(card: null, loading: true),
        HomeSheetModuleStatus.loading,
      );
    });
  });
}

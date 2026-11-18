// 演示房间(规格 welcome-tour):内容、打牌本地会话、缩短说明、
// 引导步骤、收尾卡。ProviderScope 里**只**覆盖「已看过」仓库——
// 页面若碰到任何 Firebase / Ably provider,测试环境会直接报错,
// 这也是「演示房间可离线运行」的回归保护。
import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/presentation/widget/card_fan.dart';
import 'package:cofit/features/room/presentation/widget/activity_hud.dart';
import 'package:cofit/features/welcome_tour/data/in_memory_welcome_tour_seen_repository.dart';
import 'package:cofit/features/welcome_tour/domain/entity/welcome_tour_demo.dart';
import 'package:cofit/features/welcome_tour/presentation/view/welcome_tour_view.dart';
import 'package:cofit/features/welcome_tour/presentation/widget/tour_finish_card.dart';
import 'package:cofit/features/welcome_tour/presentation/widget/tour_hint_bubble.dart';
import 'package:cofit/features/welcome_tour/provider/welcome_tour_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tick = Duration(seconds: 1);
final _demoLength = Duration(seconds: WelcomeTourDemo.sessionDurationSec + 1);

/// 页面的会话到点看的是注入的时钟,测试里和 pump 同步推进。
class _FakeClock {
  DateTime current = DateTime(2026, 11, 18, 12);
  DateTime now() => current;
}

late _FakeClock _clock;

Future<InMemoryWelcomeTourSeenRepository> _pump(WidgetTester tester) async {
  final repo = InMemoryWelcomeTourSeenRepository();
  _clock = _FakeClock();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [welcomeTourSeenRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
        ).copyWith(extensions: [CoFitColors.dark]),
        home: WelcomeTourView(now: _clock.now),
      ),
    ),
  );
  await tester.pump();
  return repo;
}

/// 小人有常驻动画,不能 pumpAndSettle;按固定时长推进假钟与帧。
Future<void> _advance(WidgetTester tester, Duration d) async {
  _clock.current = _clock.current.add(d);
  await tester.pump(d);
}

/// 像用户一样打出一张卡:点手牌进聚焦 → 点这张卡让它居中 → 上滑打出。
Future<void> _play(WidgetTester tester, String cardName) async {
  await tester.tap(find.text(cardName), warnIfMissed: false);
  await _advance(tester, _tick);
  await tester.tap(find.text(cardName), warnIfMissed: false);
  await _advance(tester, _tick);
  await tester.drag(
    find.text(cardName),
    const Offset(0, -120),
    warnIfMissed: false,
  );
  await _advance(tester, _tick);
}

/// 卸掉页面,结束会话 ticker,避免测试末尾残留 Timer。
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  final firstCard = WelcomeTourDemo.cards.first.name;
  final secondCard = WelcomeTourDemo.cards[1].name;

  testWidgets('演示房间内容:自己 + 示例小人 + 固定手牌,无 HUD 无收尾卡', (tester) async {
    await _pump(tester);

    expect(find.text('你'), findsOneWidget);
    for (final m in WelcomeTourDemo.sampleMembers) {
      expect(find.text(m.nickname!), findsOneWidget);
    }
    expect(find.byType(CardFan), findsOneWidget);
    for (final c in WelcomeTourDemo.cards) {
      expect(find.text(c.name), findsWidgets);
    }
    expect(find.byType(ActivityHud), findsNothing);
    expect(find.byType(TourFinishCard), findsNothing);
    expect(find.text(WelcomeTourView.shortenedNote), findsNothing);
    await _teardown(tester);
  });

  testWidgets('打出一张卡:自己进入该动作,HUD + 缩短说明出现;到点回待机', (tester) async {
    await _pump(tester);

    await _play(tester, firstCard);

    expect(find.byType(ActivityHud), findsOneWidget);
    expect(
      tester.widget<ActivityHud>(find.byType(ActivityHud)).status.motionId,
      WelcomeTourDemo.cards.first.motionId,
    );
    expect(
      tester.widget<ActivityHud>(find.byType(ActivityHud)).status.durationSec,
      WelcomeTourDemo.sessionDurationSec,
    );
    expect(find.text(WelcomeTourView.shortenedNote), findsOneWidget);

    await _advance(tester, _demoLength);

    expect(find.byType(ActivityHud), findsNothing);
    expect(find.text(WelcomeTourView.shortenedNote), findsNothing);
    await _teardown(tester);
  });

  testWidgets('运动中再次打牌被忽略,当前动作继续', (tester) async {
    await _pump(tester);
    await _play(tester, firstCard);
    final before = tester.widget<ActivityHud>(find.byType(ActivityHud)).status;

    await _play(tester, secondCard);

    final after = tester.widget<ActivityHud>(find.byType(ActivityHud)).status;
    expect(after.sessionId, before.sessionId);
    expect(after.templateName, firstCard);
    await _teardown(tester);
  });

  group('引导步骤', () {
    testWidgets('初始第一条;点场景第二条;打牌后第三条', (tester) async {
      await _pump(tester);
      expect(find.text(WelcomeTourView.hintSelf), findsOneWidget);
      expect(find.byType(TourHintBubble), findsOneWidget);

      await tester.tapAt(const Offset(40, 300));
      await _advance(tester, _tick);
      expect(find.text(WelcomeTourView.hintPlay), findsOneWidget);
      expect(find.text(WelcomeTourView.hintSelf), findsNothing);

      await _play(tester, firstCard);
      expect(find.text(WelcomeTourView.hintFriends), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('不点引导直接打牌:从第一条跳到第三条', (tester) async {
      await _pump(tester);
      expect(find.text(WelcomeTourView.hintSelf), findsOneWidget);

      await _play(tester, firstCard);

      expect(find.text(WelcomeTourView.hintFriends), findsOneWidget);
      expect(find.text(WelcomeTourView.hintPlay), findsNothing);
      await _teardown(tester);
    });

    testWidgets('引导不拦截手势:气泡在时手牌仍可点进聚焦', (tester) async {
      await _pump(tester);
      expect(find.byType(TourHintBubble), findsOneWidget);

      await tester.tap(find.text(firstCard), warnIfMissed: false);
      await _advance(tester, _tick);

      expect(find.text(WelcomeTourView.focusTitle), findsOneWidget);
      expect(tester.widget<CardFan>(find.byType(CardFan)).focused, isTrue);
      await _teardown(tester);
    });

    testWidgets('第一张卡倒计时结束后引导消失', (tester) async {
      await _pump(tester);
      await _play(tester, firstCard);
      await _advance(tester, _demoLength);

      expect(find.byType(TourHintBubble), findsNothing);
      await _teardown(tester);
    });
  });

  group('收尾邀请登录', () {
    testWidgets('倒计时结束 → 收尾卡;打牌仍可用;点主按钮落下已看过', (tester) async {
      final repo = await _pump(tester);
      await _play(tester, firstCard);
      expect(find.byType(TourFinishCard), findsNothing);

      await _advance(tester, _demoLength);
      expect(find.byType(TourFinishCard), findsOneWidget);
      expect(repo.seen, isFalse);

      // 收尾卡在时还能再打一张
      await _play(tester, secondCard);
      expect(find.byType(ActivityHud), findsOneWidget);
      expect(find.byType(TourFinishCard), findsOneWidget);

      await tester.tap(find.text(WelcomeTourView.finishCta));
      await _advance(tester, _tick);
      expect(repo.seen, isTrue);
      await _teardown(tester);
    });

    testWidgets('第二次完成不重复弹收尾卡', (tester) async {
      await _pump(tester);
      await _play(tester, firstCard);
      await _advance(tester, _demoLength);
      await _play(tester, secondCard);
      await _advance(tester, _demoLength);

      expect(find.byType(TourFinishCard), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('跳过:运动中也能立即离开,并落下已看过', (tester) async {
      final repo = await _pump(tester);
      await _play(tester, firstCard);

      await tester.tap(find.text(WelcomeTourView.skipLabel));
      await _advance(tester, _tick);

      expect(repo.seen, isTrue);
      await _teardown(tester);
    });
  });
}

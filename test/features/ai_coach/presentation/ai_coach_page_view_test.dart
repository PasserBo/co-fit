import 'package:cofit/core/flags/feature_flags.dart';
import 'package:cofit/core/flags/feature_flags_provider.dart';
import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/presentation/view/workout_history_page_view.dart';
import 'package:cofit/features/action/provider/action_session_history_providers.dart';
import 'package:cofit/features/ai_coach/data/in_memory_coach_consent_repository.dart';
import 'package:cofit/features/ai_coach/data/in_memory_coach_session_log.dart';
import 'package:cofit/features/ai_coach/data/replay_coach_model_client.dart';
import 'package:cofit/features/ai_coach/domain/coach_session_log.dart';
import 'package:cofit/features/ai_coach/provider/ai_coach_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/recorded_replies.dart';

Widget _app({
  required bool flag,
  required InMemoryCoachConsentRepository consent,
  ReplayCoachModelClient? client,
  List<ActionSessionRecord>? records,
}) {
  return ProviderScope(
    overrides: [
      aiCoachDebugOverrideProvider.overrideWithValue(false),
      featureFlagsValueProvider.overrideWithValue(
        FeatureFlags(betaAiCoachEnabled: flag),
      ),
      recentSessionsProvider.overrideWith((ref) async => records ?? [_record]),
      coachConsentRepositoryProvider.overrideWithValue(consent),
      coachModelClientProvider.overrideWithValue(
        client ?? ReplayCoachModelClient(recordedReplies),
      ),
      coachSessionLogFactoryProvider.overrideWithValue(
        () async => InMemoryCoachSessionLog() as CoachSessionLog,
      ),
    ],
    child: MaterialApp(
      theme: CoFitTheme.dark,
      home: const WorkoutHistoryPageView(),
    ),
  );
}

/// 至少一条记录:空状态页有无限循环的待机小人动画,pumpAndSettle 等不完。
final _record = ActionSessionRecord(
  sessionId: 's1',
  roomId: 'r1',
  userId: 'u1',
  templateId: 't1',
  templateName: '俯卧撑',
  actionKey: 'pushup',
  durationSec: 60,
  startedAt: DateTime(2026, 11, 18, 8),
  completedAt: DateTime(2026, 11, 18, 8, 1),
);

void main() {
  testWidgets('开关关闭时运动历史页没有入口', (tester) async {
    await tester.pumpWidget(
      _app(flag: false, consent: InMemoryCoachConsentRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('AI 教练'), findsNothing);
  });

  testWidgets('首次进入先显示说明;返回则不发送任何请求', (tester) async {
    final client = ReplayCoachModelClient(recordedReplies);
    final consent = InMemoryCoachConsentRepository();
    await tester.pumpWidget(_app(flag: true, consent: consent, client: client));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 教练'));
    await tester.pumpAndSettle();
    expect(find.text('同意并继续'), findsOne);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(find.text('运动历史'), findsOne);
    expect(client.requests, isEmpty);
    expect(consent.consented, isFalse);
  });

  testWidgets('同意后可用预置问题提问,卡片渲染出来;再次进入不再询问且对话清空', (tester) async {
    final consent = InMemoryCoachConsentRepository();
    await tester.pumpWidget(_app(flag: true, consent: consent));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 教练'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();
    expect(consent.consented, isTrue);

    await tester.tap(find.text('这周我练得怎么样?'));
    await tester.pumpAndSettle();
    expect(find.text('这周我练得怎么样?'), findsNWidgets(2)); // 气泡 + chip
    expect(find.text('Here is a sign-up form for your newsletter.'), findsOne);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 教练'));
    await tester.pumpAndSettle();
    expect(find.text('同意并继续'), findsNothing);
    expect(find.textContaining('就你最近的运动记录提问'), findsOne);
  });
}

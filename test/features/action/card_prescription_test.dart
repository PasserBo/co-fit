import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/action/data/in_memory_pending_session_repository.dart';
import 'package:cofit/features/action/domain/action_session_history_repository.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/domain/entity/card_amount.dart';
import 'package:cofit/features/action/domain/entity/pending_session_snapshot.dart';
import 'package:cofit/features/action/domain/entity/template_card_session.dart';
import 'package:cofit/features/action/presentation/widget/card_face_preview.dart';
import 'package:cofit/features/action/presentation/widget/workout_history_body.dart';
import 'package:cofit/features/action/usecase/record_completed_session_usecase.dart';
import 'package:cofit/features/action/usecase/recover_pending_session_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _History implements ActionSessionHistoryRepository {
  final recorded = <ActionSessionRecord>[];

  @override
  Future<void> recordSession(ActionSessionRecord record) async =>
      recorded.add(record);

  @override
  Future<List<ActionSessionRecord>> fetchRecentSessions({
    required String userId,
    int limit = 100,
  }) async => recorded;
}

ActionTemplateCard _card(Map<String, dynamic> baseline) => ActionTemplateCard(
  id: 'curl',
  name: '哑铃弯举',
  type: ActionType.strength,
  rawType: 'strength',
  source: ActionSource.official,
  ablyActionId: 'curl',
  defaultDurationSec: 60,
  intensityBaseline: baseline,
);

void main() {
  final at = DateTime(2026, 11, 25, 12);
  final baseline = {
    'label': '中等',
    'amounts': [
      {'kind': 'reps', 'value': 12, 'unit': '个'},
      {'kind': 'weight', 'value': 2.5, 'unit': 'kg'},
    ],
  };

  group('CardAmount', () {
    test('显示:整数不带小数点,带单位', () {
      expect(CardAmount.of(CardAmountKind.reps, 15).text, '15 个');
      expect(CardAmount.of(CardAmountKind.weight, 2.5).text, '2.5 kg');
      expect(CardAmount.of(CardAmountKind.distance, 400.0).text, '400 m');
      expect(
        CardAmount.textOf([
          CardAmount.of(CardAmountKind.reps, 12),
          CardAmount.of(CardAmountKind.weight, 5),
        ]),
        '12 个 · 5 kg',
      );
      expect(CardAmount.textOf(const []), '');
    });

    test('读取:丢掉不合法的项,同一种类只留第一项,不认识的种类照样保留', () {
      final amounts = CardAmount.listFrom([
        {'kind': 'reps', 'value': 12, 'unit': '个'},
        {'kind': 'reps', 'value': 99, 'unit': '个'},
        {'kind': 'weight', 'value': 0, 'unit': 'kg'},
        {'kind': 'distance', 'value': '400', 'unit': 'm'},
        {'kind': 'laps', 'value': 3, 'unit': '圈'},
        {'kind': 'weight', 'value': 2},
        'junk',
      ]);
      expect(amounts.map((a) => a.text), ['12 个', '3 圈', '2 kg']);
      expect(CardAmount.listFrom(null), isEmpty);
      expect(CardAmount.listFrom('x'), isEmpty);
    });

    test('组装强度基线:强度与量都可选', () {
      expect(CardAmount.baseline(), isEmpty);
      expect(CardAmount.baseline(label: '轻松'), {'label': '轻松'});
      final both = CardAmount.baseline(
        label: '中等',
        amounts: [CardAmount.of(CardAmountKind.reps, 12)],
      );
      expect(_card(both).intensityLabel, '中等');
      expect(_card(both).amounts.single.text, '12 个');
    });

    test('卡上没有量:空表', () {
      expect(_card(const {'label': '轻松'}).amounts, isEmpty);
      expect(_card(const {}).amounts, isEmpty);
    });
  });

  group('运动记录保存当时的强度与量', () {
    final session = TemplateCardSession(
      templateId: 'curl',
      sessionId: 's1',
      roomId: 'room',
      userId: 'me',
      status: TemplateCardSessionStatus.started,
      startedAt: at,
    );

    test('完成时抄一份卡上的强度与量', () async {
      final history = _History();
      final record = await RecordCompletedSessionUsecase(
        history,
        now: () => at.add(const Duration(minutes: 1)),
      ).execute(session: session, card: _card(baseline));

      expect(record.intensityLabel, '中等');
      expect(record.prescriptionText, '中等 · 12 个 · 2.5 kg');

      // 写入 → 读回一致;之后卡怎么改都不影响这条记录
      final back = ActionSessionRecord.fromMap(record.toMap());
      expect(back.prescriptionText, '中等 · 12 个 · 2.5 kg');
    });

    test('卡上什么都没有:记录里不写这两个字段', () async {
      final record = await RecordCompletedSessionUsecase(
        _History(),
        now: () => at,
      ).execute(session: session, card: _card(const {}));
      expect(record.toMap().keys, isNot(contains('intensityLabel')));
      expect(record.toMap().keys, isNot(contains('amounts')));
      expect(record.prescriptionText, '');
    });

    test('以前的记录(没有这两个字段):照常读取', () {
      final old = ActionSessionRecord.fromMap({
        'sessionId': 's0',
        'templateName': '深蹲',
        'durationSec': 60,
        'completedAt': at,
        'startedAt': at,
      });
      expect(old.intensityLabel, isNull);
      expect(old.amounts, isEmpty);
    });

    test('App 被结束后补记:强度与量跟着本机快照走', () async {
      final card = _card(baseline);
      final snapshot = PendingSessionSnapshot(
        sessionId: 's1',
        roomId: 'room',
        userId: 'me',
        templateId: card.id,
        templateName: card.name,
        actionKey: card.rawType,
        durationSec: 60,
        startedAt: at,
        intensityLabel: card.intensityLabel,
        amounts: card.amounts,
      );
      // 快照经过本机保存的往返
      final restored = PendingSessionSnapshot.fromMap(snapshot.toMap())!;
      expect(restored.amounts, card.amounts);

      final pending = InMemoryPendingSessionRepository();
      await pending.save(restored);
      final history = _History();
      await RecoverPendingSessionUsecase(
        pending,
        history,
        now: () => at.add(const Duration(minutes: 5)),
      ).execute(userId: 'me');
      expect(history.recorded.single.prescriptionText, '中等 · 12 个 · 2.5 kg');
    });
  });

  group('显示', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: CoFitTheme.dark,
        home: Scaffold(body: child),
      ),
    );

    testWidgets('卡面:有量时多一行;没有时不显示', (tester) async {
      await pump(
        tester,
        const CardFacePreview(
          name: '哑铃弯举',
          type: ActionType.strength,
          durationSec: 60,
          intensityLabel: '中等',
          amountsText: '12 个 · 2.5 kg',
        ),
      );
      expect(find.text('12 个 · 2.5 kg'), findsOneWidget);

      await pump(
        tester,
        const CardFacePreview(
          name: '肩颈拉伸',
          type: ActionType.flexibility,
          durationSec: 60,
          amountsText: '',
        ),
      );
      expect(find.byKey(const ValueKey('card_face_amounts')), findsNothing);
    });

    testWidgets('运动历史行:带出当时的强度与量', (tester) async {
      final record = ActionSessionRecord(
        sessionId: 's1',
        roomId: 'room',
        userId: 'me',
        templateId: 'curl',
        templateName: '哑铃弯举',
        actionKey: 'strength',
        durationSec: 60,
        startedAt: at,
        completedAt: at,
        intensityLabel: '中等',
        amounts: [CardAmount.of(CardAmountKind.reps, 12)],
      );
      await pump(tester, WorkoutHistoryBody(records: [record], now: at));
      expect(find.text('力量 · 1 min · 中等 · 12 个'), findsOneWidget);
    });
  });
}

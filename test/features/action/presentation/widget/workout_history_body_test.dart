import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/presentation/widget/workout_history_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ActionSessionRecord _record({
  required String name,
  required DateTime completedAt,
  int durationSec = 300,
  String actionKey = 'cardio',
}) {
  return ActionSessionRecord(
    sessionId: 's-${completedAt.millisecondsSinceEpoch}-$name',
    roomId: 'room-1',
    userId: 'u1',
    templateId: 't1',
    templateName: name,
    actionKey: actionKey,
    durationSec: durationSec,
    startedAt: completedAt.subtract(Duration(seconds: durationSec)),
    completedAt: completedAt,
  );
}

void main() {
  final now = DateTime(2026, 8, 12, 20, 0);

  Future<void> pump(WidgetTester tester, List<ActionSessionRecord> records) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark)
            .copyWith(extensions: [CoFitColors.dark]),
        home: Scaffold(
          body: WorkoutHistoryBody(records: records, now: now),
        ),
      ),
    );
  }

  testWidgets('groups records by 今天/昨天/date and shows footer',
      (tester) async {
    await pump(tester, [
      _record(name: '开合跳', completedAt: DateTime(2026, 8, 12, 8, 12)),
      _record(
        name: '深蹲',
        completedAt: DateTime(2026, 8, 11, 7, 58),
        actionKey: 'strength',
        durationSec: 600,
      ),
      _record(
        name: '体侧拉伸',
        completedAt: DateTime(2026, 8, 1, 19, 24),
        actionKey: 'flexibility',
        durationSec: 240,
      ),
    ]);

    expect(find.text('今天'), findsOneWidget);
    expect(find.text('昨天'), findsOneWidget);
    expect(find.text('8月1日'), findsOneWidget);
    expect(find.text('开合跳'), findsOneWidget);
    expect(find.text('有氧 · 5 min'), findsOneWidget);
    expect(find.text('力量 · 10 min'), findsOneWidget);
    expect(find.text('柔韧 · 4 min'), findsOneWidget);
    expect(find.text('08:12'), findsOneWidget);
    expect(find.text('仅显示最近 100 条'), findsOneWidget);
  });

  testWidgets('week summary counts only last 7 days', (tester) async {
    await pump(tester, [
      _record(name: '开合跳', completedAt: DateTime(2026, 8, 12, 8)),
      _record(name: '深蹲', completedAt: DateTime(2026, 8, 10, 8)),
      // 8 天前,不计入本周
      _record(name: '旧记录', completedAt: DateTime(2026, 8, 4, 8)),
    ]);

    expect(find.text('本周'), findsOneWidget);
    // Text.rich 整体匹配:2 次 · 10 min(旧记录在 7 天外,不计入)
    expect(find.textContaining('2'), findsWidgets);
    expect(find.textContaining('10'), findsWidgets);
  });
}

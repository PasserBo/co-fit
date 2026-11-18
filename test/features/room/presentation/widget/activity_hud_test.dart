import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:cofit/features/room/presentation/widget/activity_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, UserActivityStatusEntity status) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ).copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: Center(child: ActivityHud(status: status)),
      ),
    ),
  );
}

CircularProgressIndicator _ring(WidgetTester tester) {
  return tester.widget<CircularProgressIndicator>(
    find.byType(CircularProgressIndicator),
  );
}

void main() {
  testWidgets('shows template name and determinate progress', (tester) async {
    await _pump(
      tester,
      const UserActivityStatusEntity(
        activityState: UserActivityState.active,
        actionKey: 'squat',
        templateName: '深蹲',
        durationSec: 60,
        remainingSec: 15,
      ),
    );
    expect(find.text('当前动作'), findsOneWidget);
    expect(find.text('深蹲'), findsOneWidget);
    expect(find.text('squat'), findsNothing);
    expect(_ring(tester).value, closeTo(0.75, 1e-9));
  });

  testWidgets('falls back to actionKey, then to a generic label', (
    tester,
  ) async {
    await _pump(
      tester,
      const UserActivityStatusEntity(
        activityState: UserActivityState.active,
        actionKey: 'plank',
      ),
    );
    expect(find.text('plank'), findsOneWidget);

    await _pump(
      tester,
      const UserActivityStatusEntity(activityState: UserActivityState.active),
    );
    expect(find.text('运动中'), findsOneWidget);
  });

  testWidgets('missing duration or remaining makes the ring indeterminate', (
    tester,
  ) async {
    await _pump(
      tester,
      const UserActivityStatusEntity(
        activityState: UserActivityState.active,
        templateName: '开合跳',
        durationSec: 45,
      ),
    );
    expect(_ring(tester).value, isNull);

    await _pump(
      tester,
      const UserActivityStatusEntity(
        activityState: UserActivityState.active,
        templateName: '开合跳',
        durationSec: 0,
        remainingSec: 0,
      ),
    );
    expect(_ring(tester).value, isNull);
  });

  testWidgets('progress is clamped to 0..1', (tester) async {
    await _pump(
      tester,
      const UserActivityStatusEntity(
        activityState: UserActivityState.active,
        templateName: '俯卧撑',
        durationSec: 30,
        remainingSec: 90,
      ),
    );
    expect(_ring(tester).value, 0.0);
  });
}

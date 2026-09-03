import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/presentation/widget/card_face_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('renders name, meta and custom badge', (tester) async {
    await _pump(
      tester,
      const CardFacePreview(
        name: '壶铃摆荡',
        type: ActionType.strength,
        durationSec: 480,
        intensityLabel: '中等',
        source: ActionSource.custom,
        large: true,
      ),
    );

    expect(find.text('壶铃摆荡'), findsOneWidget);
    expect(find.text('力量 · 8 min · 中等'), findsOneWidget);
    expect(find.text('自建'), findsOneWidget);
  });

  testWidgets('empty name falls back to 未命名; sub-minute shows seconds',
      (tester) async {
    await _pump(
      tester,
      const CardFacePreview(
        name: '',
        type: ActionType.cardio,
        durationSec: 45,
      ),
    );

    expect(find.text('未命名'), findsOneWidget);
    expect(find.text('有氧 · 45 s'), findsOneWidget);
    expect(find.text('官方'), findsNothing); // 预览态不显示来源徽章
  });
}

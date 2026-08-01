import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/presentation/widget/library_tab_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ActionTemplateCard _card(
  String id,
  ActionType type, {
  ActionSource source = ActionSource.official,
}) =>
    ActionTemplateCard(
      id: id,
      name: id,
      type: type,
      rawType: type.name,
      source: source,
      ablyActionId: id,
      defaultDurationSec: 600,
    );

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('groups cards into type sections and skips empty types',
      (tester) async {
    await _pump(
      tester,
      LibraryTabBody(
        cards: [
          _card('深蹲', ActionType.strength),
          _card('硬拉', ActionType.strength),
          _card('开合跳', ActionType.cardio),
        ],
      ),
    );

    expect(find.text('力量训练'), findsOneWidget);
    expect(find.text('有氧训练'), findsOneWidget);
    expect(find.text('核心'), findsNothing);
    expect(find.text('柔韧'), findsNothing);
    expect(find.text('创建卡片'), findsOneWidget);
  });

  testWidgets('fires onCardTap and onCreateCard', (tester) async {
    ActionTemplateCard? tapped;
    var created = false;
    await _pump(
      tester,
      LibraryTabBody(
        cards: [_card('深蹲', ActionType.strength)],
        onCardTap: (card) => tapped = card,
        onCreateCard: () => created = true,
      ),
    );

    await tester.tap(find.text('深蹲'));
    expect(tapped?.id, '深蹲');

    await tester.tap(find.text('创建卡片'));
    expect(created, isTrue);
  });
}

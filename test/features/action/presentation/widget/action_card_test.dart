import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/presentation/widget/action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ActionTemplateCard _card({ActionSource source = ActionSource.official}) {
  return ActionTemplateCard(
    id: 'tpl_squat',
    name: '深蹲',
    type: ActionType.strength,
    rawType: 'strength_basic',
    source: source,
    ablyActionId: 'squat',
    defaultDurationSec: 600,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  // 不用 CoFitTheme.dark:widget test 里避免 google_fonts 的运行时字体加载,
  // 组件本身只依赖 CoFitColors extension。
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: Center(child: SizedBox(width: 140, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders name, duration and official badge by default',
      (tester) async {
    await _pump(tester, ActionCard(card: _card()));

    expect(find.text('深蹲'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('官方'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('friend-shared card shows blue 好友 badge', (tester) async {
    await _pump(
        tester, ActionCard(card: _card(source: ActionSource.friendShared)));

    expect(find.text('好友'), findsOneWidget);
  });

  testWidgets('custom card appends · 自建 and exposes share button',
      (tester) async {
    var shared = false;
    await _pump(
      tester,
      ActionCard(
        card: _card(source: ActionSource.custom),
        onShare: () => shared = true,
      ),
    );

    expect(find.text('10 min · 自建'), findsOneWidget);
    expect(find.text('官方'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_outward));
    expect(shared, isTrue);
  });

  testWidgets('selected state shows check badge', (tester) async {
    await _pump(tester, ActionCard(card: _card(), selected: true));

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('editing state shows remove badge and fires onRemove',
      (tester) async {
    var removed = false;
    await _pump(
      tester,
      ActionCard(card: _card(), editing: true, onRemove: () => removed = true),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
    expect(removed, isTrue);
  });

  testWidgets('card tap fires onTap', (tester) async {
    var tapped = false;
    await _pump(tester, ActionCard(card: _card(), onTap: () => tapped = true));

    await tester.tap(find.text('深蹲'));
    expect(tapped, isTrue);
  });
}

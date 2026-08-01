import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/core/theme/cofit_dimens.dart';
import 'package:cofit/core/widget/floating_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _destinations = [
  DockDestination(icon: Icons.home_rounded, label: '房间'),
  DockDestination(icon: Icons.style_rounded, label: '牌库'),
  DockDestination(icon: Icons.person_rounded, label: '我的'),
];

Future<void> _pump(
  WidgetTester tester, {
  int current = 0,
  ValueChanged<int>? onSelect,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: FloatingDock(
            destinations: _destinations,
            currentIndex: current,
            onSelect: onSelect ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

double _slotHeight(WidgetTester tester, IconData icon) {
  final slot = find.ancestor(
    of: find.byIcon(icon),
    matching: find.byType(ClipRect),
  );
  return tester.getSize(slot.first).height;
}

void main() {
  testWidgets('collapsed dock only shows the current destination',
      (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(_slotHeight(tester, Icons.home_rounded),
        CoFitDimens.sizeDockItem);
    expect(_slotHeight(tester, Icons.style_rounded), 0);
    expect(_slotHeight(tester, Icons.person_rounded), 0);
  });

  testWidgets('tapping current icon expands all destinations',
      (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();

    expect(_slotHeight(tester, Icons.style_rounded),
        greaterThan(CoFitDimens.sizeDockItem));
    expect(_slotHeight(tester, Icons.person_rounded),
        greaterThan(CoFitDimens.sizeDockItem));
  });

  testWidgets('selecting another destination fires onSelect and collapses',
      (tester) async {
    int? selected;
    await _pump(tester, onSelect: (i) => selected = i);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.style_rounded));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(_slotHeight(tester, Icons.style_rounded), 0);
  });

  testWidgets('auto-collapses after the idle timeout', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(_slotHeight(tester, Icons.style_rounded),
        greaterThan(CoFitDimens.sizeDockItem));

    await tester.pump(
      CoFitMotion.dockAutoCollapse + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    expect(_slotHeight(tester, Icons.style_rounded), 0);
  });
}

import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/core/widget/cofit_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Future<void> Function(BuildContext) onTap) {
  return MaterialApp(
    theme: CoFitTheme.dark,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('confirm sheet returns true on confirm, false on cancel', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _host((context) async {
        result = await showCoFitConfirmSheet(
          context,
          title: '删除?',
          message: '不可撤销',
          confirmLabel: '删除',
          danger: true,
        );
      }),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('删除?'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('text input sheet trims, validates and returns value', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      _host((context) async {
        result = await showCoFitTextInputSheet(
          context,
          title: '编辑昵称',
          label: '昵称',
          initialValue: 'old',
          validator: (v) => v.length > 5 ? '太长' : null,
        );
      }),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  toolongname ');
    await tester.pump();
    expect(find.text('太长'), findsOneWidget);
    final save = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(save.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  new ');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(result, 'new');
  });
}

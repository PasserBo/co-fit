import 'package:cofit/core/navigation/app_shell.dart';
import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dock switches the visible page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark)
            .copyWith(extensions: [CoFitColors.dark]),
        home: AppShell(
          pages: const [
            Center(child: Text('房间页')),
            Center(child: Text('牌库页')),
            Center(child: Text('我的页')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // IndexedStack 下所有页面都在树里,但只有当前页可见
    expect(
      tester.getSemantics(find.text('房间页')),
      isNotNull,
    );

    // 展开 dock(当前=房间图标),切到牌库
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.style_rounded));
    await tester.pumpAndSettle();

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 1);
  });
}

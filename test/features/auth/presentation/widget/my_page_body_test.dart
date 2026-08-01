import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/auth/presentation/widget/my_page_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onEditAvatar,
  VoidCallback? onSignOut,
  String? email = 'xiaoman@example.com',
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: MyPageBody(
          displayName: 'xiaoman',
          handle: 'a1b2c3',
          email: email,
          roomCount: 3,
          deckCount: 2,
          cardCount: 8,
          onEditAvatar: onEditAvatar,
          onSignOut: onSignOut,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders hero identity, stats and email', (tester) async {
    await _pump(tester);

    expect(find.text('xiaoman'), findsOneWidget);
    expect(find.text('@a1b2c3'), findsOneWidget);
    expect(find.text('编辑形象'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('加入房间'), findsOneWidget);
    expect(find.text('牌组'), findsOneWidget);
    expect(find.text('卡牌'), findsOneWidget);
    expect(find.text('xiaoman@example.com'), findsOneWidget);
  });

  testWidgets('missing email falls back to 未绑定', (tester) async {
    await _pump(tester, email: null);

    expect(find.text('未绑定'), findsOneWidget);
  });

  testWidgets('fires edit-avatar and sign-out callbacks', (tester) async {
    var edited = false;
    var signedOut = false;
    await _pump(
      tester,
      onEditAvatar: () => edited = true,
      onSignOut: () => signedOut = true,
    );

    await tester.tap(find.text('编辑形象'));
    expect(edited, isTrue);

    await tester.scrollUntilVisible(find.text('退出登录'), 100);
    await tester.tap(find.text('退出登录'));
    expect(signedOut, isTrue);
  });
}

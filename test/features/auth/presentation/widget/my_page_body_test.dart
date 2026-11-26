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
      theme: ThemeData(
        brightness: Brightness.dark,
      ).copyWith(extensions: [CoFitColors.dark]),
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

    // hero 区 + 账号分组「昵称」行各出现一次
    expect(find.text('xiaoman'), findsNWidgets(2));
    expect(find.text('昵称'), findsOneWidget);
    expect(find.text('@a1b2c3'), findsOneWidget);
    // 无 onEditAvatar 回调时不渲「编辑形象」(v2 功能,首版无占位入口)
    expect(find.text('编辑形象'), findsNothing);
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

  group('通知分组(add-partner-start-push)', () {
    Future<void> pumpPush(
      WidgetTester tester, {
      bool? on,
      ValueChanged<bool>? onChanged,
      VoidCallback? onOpenSettings,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
          ).copyWith(extensions: [CoFitColors.dark]),
          home: Scaffold(
            body: MyPageBody(
              displayName: 'xiaoman',
              handle: 'a1b2c3',
              roomCount: 1,
              deckCount: 1,
              cardCount: 1,
              partnerStartPushOn: on,
              onPartnerStartPushChanged: onChanged,
              onOpenSystemNotificationSettings: onOpenSettings,
            ),
          ),
        ),
      );
    }

    testWidgets('设置未加载(null)时不显示分组', (tester) async {
      await pumpPush(tester);
      expect(find.text('伙伴开始运动时通知我'), findsNothing);
    });

    testWidgets('点开关行切换', (tester) async {
      bool? changed;
      await pumpPush(tester, on: true, onChanged: (v) => changed = v);
      await tester.scrollUntilVisible(find.text('伙伴开始运动时通知我'), 100);
      expect(find.byType(Switch), findsOneWidget);
      await tester.tap(find.text('伙伴开始运动时通知我'));
      expect(changed, isFalse);
    });

    testWidgets('系统权限被拒:显示说明行,点了去系统设置', (tester) async {
      var opened = false;
      await pumpPush(
        tester,
        on: true,
        onChanged: (_) {},
        onOpenSettings: () => opened = true,
      );
      await tester.scrollUntilVisible(find.text('系统通知已关闭'), 100);
      await tester.tap(find.text('系统通知已关闭'));
      expect(opened, isTrue);
    });

    testWidgets('系统权限正常:不显示说明行', (tester) async {
      await pumpPush(tester, on: false, onChanged: (_) {});
      expect(find.text('系统通知已关闭'), findsNothing);
    });
  });
}

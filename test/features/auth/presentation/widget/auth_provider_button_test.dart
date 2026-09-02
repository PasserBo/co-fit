import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/auth/presentation/widget/auth_provider_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark)
          .copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: AuthProviderButton(
          icon: const Icon(Icons.login),
          label: '使用 Google 登录',
          onPressed: onPressed,
          isLoading: isLoading,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders label and fires onPressed', (tester) async {
    var tapped = false;
    await _pump(tester, onPressed: () => tapped = true);

    expect(find.text('使用 Google 登录'), findsOneWidget);
    await tester.tap(find.byType(AuthProviderButton));
    expect(tapped, isTrue);
  });

  testWidgets('loading state shows spinner and blocks taps', (tester) async {
    var tapped = false;
    await _pump(tester, onPressed: () => tapped = true, isLoading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('使用 Google 登录'), findsNothing);
    await tester.tap(find.byType(AuthProviderButton));
    expect(tapped, isFalse);
  });
}

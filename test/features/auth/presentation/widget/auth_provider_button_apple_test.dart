import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/auth/presentation/widget/auth_provider_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('apple variant uses HIG black-on-light styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark)
            .copyWith(extensions: [CoFitColors.dark]),
        home: Scaffold(
          body: AuthProviderButton(
            apple: true,
            icon: const Icon(Icons.apple_rounded),
            label: '通过 Apple 登录',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('通过 Apple 登录'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final style = button.style!;
    // gray-50 底(textPrimary)+ gray-950 字(primaryOn),#19a HIG 黑白款
    expect(
      style.backgroundColor?.resolve({}),
      CoFitColors.dark.textPrimary,
    );
    expect(
      style.foregroundColor?.resolve({}),
      CoFitColors.dark.primaryOn,
    );
  });
}

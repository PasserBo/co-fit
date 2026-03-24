import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CoFit placeholder widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('CoFit'),
        ),
      ),
    );

    expect(find.text('CoFit'), findsOneWidget);
  });
}

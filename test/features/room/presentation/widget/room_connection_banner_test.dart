import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/features/room/presentation/widget/room_connection_banner.dart';
import 'package:cofit/features/room/provider/room_connection_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, RoomConnectionStatus status) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ).copyWith(extensions: [CoFitColors.dark]),
      home: Scaffold(
        body: Center(child: RoomConnectionBanner(status: status)),
      ),
    ),
  );
}

void main() {
  testWidgets('live renders nothing', (tester) async {
    await _pump(tester, RoomConnectionStatus.live);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('each non-live status shows its label', (tester) async {
    for (final status in RoomConnectionStatus.values) {
      final label = RoomConnectionBanner.labelOf(status);
      if (label == null) continue;
      await _pump(tester, status);
      await tester.pump();
      expect(find.text(label), findsOneWidget, reason: '$status');
    }
  });
}

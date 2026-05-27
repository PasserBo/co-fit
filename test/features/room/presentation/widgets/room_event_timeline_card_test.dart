import 'package:cofit/features/room/data/room_event.dart';
import 'package:cofit/features/room/presentation/widgets/room_event_timeline_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows template metadata for template card events', (
    WidgetTester tester,
  ) async {
    final event = RoomEvent(
      eventId: 'evt-1',
      roomId: 'room-1',
      userId: 'user-1',
      type: RoomEventType.actionStarted,
      timestamp: DateTime.parse('2026-05-27T12:34:56Z'),
      payload: RoomEventPayload(
        schemaVersion: 1,
        actionKey: 'strength_basic',
        durationSec: 1200,
        remainingSec: 1200,
        sessionId: 'session-1',
        customData: const {
          'templateId': 'tpl_strength_basic',
          'templateName': '基础举铁训练',
          'ablyActionId': '1',
          'intensityLabel': '20-30kg',
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomEventTimelineCard(events: [event]),
        ),
      ),
    );

    expect(
      find.text('user-1 -> action_started (基础举铁训练)'),
      findsOneWidget,
    );
    expect(find.textContaining('templateId=tpl_strength_basic'), findsOneWidget);
    expect(find.textContaining('ablyActionId=1'), findsOneWidget);
    expect(find.textContaining('intensity=20-30kg'), findsOneWidget);
    expect(find.byIcon(Icons.style_outlined), findsOneWidget);
  });

  testWidgets('keeps existing format for non-template events', (
    WidgetTester tester,
  ) async {
    final event = RoomEvent(
      eventId: 'evt-2',
      roomId: 'room-1',
      userId: 'user-2',
      type: RoomEventType.actionPaused,
      timestamp: DateTime.parse('2026-05-27T12:44:56Z'),
      payload: RoomEventPayload(
        schemaVersion: 1,
        actionKey: 'strength_basic',
        durationSec: 1200,
        remainingSec: 1100,
        sessionId: 'session-2',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomEventTimelineCard(events: [event]),
        ),
      ),
    );

    expect(find.text('user-2 -> action_paused'), findsOneWidget);
    expect(find.textContaining('template='), findsNothing);
    expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
  });
}

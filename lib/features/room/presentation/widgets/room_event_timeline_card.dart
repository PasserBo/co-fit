import 'package:flutter/material.dart';

import '../../data/room_event.dart';

class RoomEventTimelineCard extends StatelessWidget {
  const RoomEventTimelineCard({
    required this.events,
    this.limit = 30,
    super.key,
  });

  final List<RoomEvent> events;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Timeline (${events.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('No events received yet.')
            else
              ...events.take(limit).map((event) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt_outlined),
                  title: Text('${event.userId} -> ${event.type}'),
                  subtitle: Text(
                    '${event.timestamp.toIso8601String()} | '
                    'action=${event.payload.actionKey} '
                    'remaining=${event.payload.remainingSec} '
                    'session=${event.payload.sessionId} '
                    'v=${event.payload.schemaVersion}',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

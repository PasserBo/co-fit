import 'package:flutter/material.dart';

import '../../domain/entity/room_event.dart';

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
                final templateName = _readCustomString(
                  event.payload.customData,
                  'templateName',
                );
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    templateName == null
                        ? Icons.bolt_outlined
                        : Icons.style_outlined,
                  ),
                  title: Text(_buildTitle(event, templateName: templateName)),
                  subtitle: Text(
                    _buildSubtitle(event, templateName: templateName),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _buildTitle(RoomEvent event, {String? templateName}) {
    if (templateName == null) {
      return '${event.userId} -> ${event.type}';
    }
    return '${event.userId} -> ${event.type} (${templateName})';
  }

  String _buildSubtitle(RoomEvent event, {String? templateName}) {
    final payload = event.payload;
    final parts = <String>[
      event.timestamp.toIso8601String(),
      if (templateName != null) 'template=${templateName}',
      'action=${payload.actionKey}',
      'duration=${payload.durationSec}',
      'remaining=${payload.remainingSec}',
      'session=${payload.sessionId}',
      'v=${payload.schemaVersion}',
    ];

    final templateId = _readCustomString(payload.customData, 'templateId');
    final ablyActionId = _readCustomString(payload.customData, 'ablyActionId');
    final intensityLabel = _readCustomString(payload.customData, 'intensityLabel');
    if (templateId != null) {
      parts.add('templateId=$templateId');
    }
    if (ablyActionId != null) {
      parts.add('ablyActionId=$ablyActionId');
    }
    if (intensityLabel != null) {
      parts.add('intensity=$intensityLabel');
    }

    return parts.join(' | ');
  }

  String? _readCustomString(Map<String, dynamic> customData, String key) {
    final value = customData[key];
    if (value == null) {
      return null;
    }
    final normalized = value.toString().trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

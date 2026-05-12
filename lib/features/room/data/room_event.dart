enum RoomEventType {
  actionStarted('action_started'),
  actionPaused('action_paused'),
  actionResumed('action_resumed'),
  actionCompleted('action_completed');

  const RoomEventType(this.value);

  final String value;

  static RoomEventType? fromValue(String raw) {
    for (final type in RoomEventType.values) {
      if (type.value == raw) {
        return type;
      }
    }
    return null;
  }
}

class RoomEvent {
  RoomEvent({
    required this.eventId,
    required this.roomId,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.payload,
  });

  final String eventId;
  final String roomId;
  final String userId;
  final RoomEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'roomId': roomId,
      'userId': userId,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }

  static RoomEvent? fromMap(Map<String, dynamic> source) {
    final rawType = source['type'] as String?;
    final parsedType = rawType == null ? null : RoomEventType.fromValue(rawType);
    if (parsedType == null) {
      return null;
    }

    final rawTimestamp = source['timestamp'] as String?;
    final timestamp = rawTimestamp == null
        ? null
        : DateTime.tryParse(rawTimestamp)?.toLocal();
    if (timestamp == null) {
      return null;
    }

    final eventId = source['eventId'] as String?;
    final roomId = source['roomId'] as String?;
    final userId = source['userId'] as String?;
    if (eventId == null || roomId == null || userId == null) {
      return null;
    }

    final rawPayload = source['payload'];
    final payload = rawPayload is Map
        ? rawPayload.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : <String, dynamic>{};

    return RoomEvent(
      eventId: eventId,
      roomId: roomId,
      userId: userId,
      type: parsedType,
      timestamp: timestamp,
      payload: payload,
    );
  }
}

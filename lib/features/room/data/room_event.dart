class RoomEventType {
  static const String actionStarted = 'action_started';
  static const String actionPaused = 'action_paused';
  static const String actionResumed = 'action_resumed';
  static const String actionCompleted = 'action_completed';
}

class RoomEventPayload {
  RoomEventPayload({
    required this.schemaVersion,
    required this.actionKey,
    required this.durationSec,
    required this.remainingSec,
    required this.sessionId,
    this.customData = const {},
  });

  factory RoomEventPayload.fromMap(Map<String, dynamic> source) {
    final knownKeys = {
      'schemaVersion',
      'actionKey',
      'durationSec',
      'remainingSec',
      'sessionId',
    };
    final custom = Map<String, dynamic>.from(source)
      ..removeWhere((key, _) => knownKeys.contains(key));

    return RoomEventPayload(
      schemaVersion: _asInt(source['schemaVersion']) ?? 1,
      actionKey: (source['actionKey'] ?? 'unknown').toString(),
      durationSec: _asInt(source['durationSec']) ?? 0,
      remainingSec: _asInt(source['remainingSec']) ?? 0,
      sessionId: (source['sessionId'] ?? '').toString(),
      customData: custom,
    );
  }

  final int schemaVersion;
  final String actionKey;
  final int durationSec;
  final int remainingSec;
  final String sessionId;
  final Map<String, dynamic> customData;

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'actionKey': actionKey,
      'durationSec': durationSec,
      'remainingSec': remainingSec,
      'sessionId': sessionId,
      ...customData,
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
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
  final String type;
  final DateTime timestamp;
  final RoomEventPayload payload;

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'roomId': roomId,
      'userId': userId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload.toMap(),
    };
  }

  static RoomEvent fromMap(Map<String, dynamic> source) {
    final rawType = source['type'] as String?;
    final parsedType = rawType ?? 'unknown';

    final rawTimestamp = source['timestamp'] as String?;
    final timestamp = rawTimestamp == null
        ? DateTime.now().toLocal()
        : (DateTime.tryParse(rawTimestamp)?.toLocal() ?? DateTime.now().toLocal());

    final eventId = source['eventId'] as String?;
    final roomId = source['roomId'] as String?;
    final userId = source['userId'] as String?;

    final rawPayload = source['payload'];
    final payloadMap = rawPayload is Map
        ? rawPayload.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : <String, dynamic>{};

    return RoomEvent(
      eventId: eventId ?? 'missing-event-id',
      roomId: roomId ?? 'missing-room-id',
      userId: userId ?? 'unknown-user',
      type: parsedType,
      timestamp: timestamp,
      payload: RoomEventPayload.fromMap(payloadMap),
    );
  }
}

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'dart:convert';

class AblyService {
  AblyService({
    required String apiKey,
    required String clientId,
  }) : _realtime = ably.Realtime(
          options: ably.ClientOptions(
            key: apiKey,
            clientId: clientId,
            autoConnect: false,
          ),
        );

  final ably.Realtime _realtime;

  ably.Realtime get realtime => _realtime;

  Future<void> connect() async {
    _realtime.connect();
  }

  Future<void> disconnect() async {
    _realtime.close();
  }

  Stream<ably.ConnectionStateChange> watchConnectionState() {
    return _realtime.connection.on();
  }

  Future<void> publishRoomEvent({
    required String roomId,
    required String eventName,
    required Map<String, dynamic> payload,
  }) async {
    final dynamic channel = _getRoomChannel(roomId);
    await channel.publish(eventName, payload);
  }

  Stream<Map<String, dynamic>> watchRoomEvents({
    required String roomId,
  }) {
    final dynamic channel = _getRoomChannel(roomId);
    return (channel.subscribe() as Stream<dynamic>).map((dynamic message) {
      final dynamic data = message.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
      return <String, dynamic>{};
    }).where((event) => event.isNotEmpty);
  }

  Future<void> enterPresence({
    required String roomId,
    required String userId,
  }) async {
    final dynamic channel = _getRoomChannel(roomId);
    await channel.presence.enter({'userId': userId});
  }

  Future<void> leavePresence({
    required String roomId,
  }) async {
    final dynamic channel = _getRoomChannel(roomId);
    await channel.presence.leave();
  }

  Stream<List<Map<String, String>>> watchPresence({
    required String roomId,
  }) {
    final dynamic channel = _getRoomChannel(roomId);
    final Stream<dynamic> updates = channel.presence.subscribe();
    return (() async* {
      yield await _getPresenceMembers(roomId);
      await for (final _ in updates) {
        yield await _getPresenceMembers(roomId);
      }
    })();
  }

  Future<List<Map<String, String>>> _getPresenceMembers(String roomId) async {
    final dynamic channel = _getRoomChannel(roomId);
    final dynamic members = await channel.presence.get();
    if (members is! Iterable) {
      return const [];
    }

    return members.map<Map<String, String>>((dynamic member) {
      final clientId = (member.clientId ?? '').toString();
      final dynamic memberData = member.data;
      String userId = clientId;
      if (memberData is Map && memberData['userId'] != null) {
        userId = memberData['userId'].toString();
      }
      return {
        'clientId': clientId,
        'userId': userId,
      };
    }).toList(growable: false);
  }

  dynamic _getRoomChannel(String roomId) {
    final channelName = 'room:$roomId:events';
    return _realtime.channels.get(channelName);
  }

  Future<void> dispose() async {
    _realtime.close();
  }
}

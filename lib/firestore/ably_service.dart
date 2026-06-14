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

  Stream<ably.ChannelStateChange> watchRoomChannelState({
    required String roomId,
  }) {
    return _getRoomChannel(roomId).on();
  }

  ably.ChannelState getRoomChannelState(String roomId) {
    return _getRoomChannel(roomId).state;
  }

  Future<void> publishRoomEvent({
    required String roomId,
    required String eventName,
    required Map<String, dynamic> payload,
  }) async {
    final channel = _getRoomChannel(roomId);
    await channel.publish(name: eventName, data: payload);
  }

  Stream<Map<String, dynamic>> watchRoomEvents({
    required String roomId,
  }) {
    final channel = _getRoomChannel(roomId);
    return channel.subscribe().map((message) {
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
    final channel = _getRoomChannel(roomId);
    await channel.presence.enter({'userId': userId});
  }

  Future<void> leavePresence({
    required String roomId,
  }) async {
    final channel = _getRoomChannel(roomId);
    await channel.presence.leave();
  }

  Future<void> updatePresenceData({
    required String roomId,
    required Map<String, dynamic> data,
  }) async {
    final channel = _getRoomChannel(roomId);
    await channel.presence.update(data);
  }

  Stream<List<Map<String, dynamic>>> watchPresence({
    required String roomId,
  }) {
    final channel = _getRoomChannel(roomId);
    final updates = channel.presence.subscribe();
    return (() async* {
      yield await _getPresenceMembers(roomId);
      await for (final _ in updates) {
        yield await _getPresenceMembers(roomId);
      }
    })();
  }

  Future<List<Map<String, dynamic>>> _getPresenceMembers(String roomId) async {
    final channel = _getRoomChannel(roomId);
    final members = await channel.presence.get();
    return members.map<Map<String, dynamic>>((member) {
      final clientId = (member.clientId ?? '').toString();
      final memberData = _normalizePresenceData(member.data);
      String userId = clientId;
      if (memberData['userId'] != null) {
        userId = memberData['userId'].toString();
      }
      return {
        'clientId': clientId,
        'userId': userId,
        'data': memberData,
      };
    }).toList(growable: false);
  }

  Map<String, dynamic> _normalizePresenceData(Object? rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is Map) {
      return rawData.map((key, value) => MapEntry(key.toString(), value));
    }
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  ably.RealtimeChannel _getRoomChannel(String roomId) {
    final channelName = 'room:$roomId:events';
    return _realtime.channels.get(channelName);
  }

  Future<void> dispose() async {
    _realtime.close();
  }
}

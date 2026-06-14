import '../../../firestore/ably_service.dart';
import '../domain/entity/room_event.dart';
import '../domain/entity/room_presence_member.dart';

class RoomRealtimeRepository {
  RoomRealtimeRepository(this._ablyService);

  final AblyService _ablyService;

  Future<void> connect() {
    return _ablyService.connect();
  }

  Future<void> disconnect() {
    return _ablyService.disconnect();
  }

  Stream<String> watchConnectionState() {
    return _ablyService.watchConnectionState().map((state) {
      return state.current.toString().split('.').last;
    });
  }

  Future<void> subscribeRoom({
    required String roomId,
    required String userId,
  }) {
    return _ablyService.enterPresence(roomId: roomId, userId: userId);
  }

  Future<void> leaveRoom({
    required String roomId,
  }) {
    return _ablyService.leavePresence(roomId: roomId);
  }

  Future<void> updatePresenceData({
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    return _ablyService.updatePresenceData(roomId: roomId, data: data);
  }

  Stream<List<RoomPresenceMember>> watchPresence({
    required String roomId,
  }) {
    return _ablyService.watchPresence(roomId: roomId).map((rawMembers) {
      return rawMembers
          .map(RoomPresenceMember.fromMap)
          .toList(growable: false);
    });
  }

  Stream<RoomEvent> watchRoomEvents({
    required String roomId,
  }) {
    return _ablyService.watchRoomEvents(roomId: roomId).map((payload) {
      return RoomEvent.fromMap(payload);
    });
  }

  Future<void> publishEvent({
    required RoomEvent event,
  }) {
    return _ablyService.publishRoomEvent(
      roomId: event.roomId,
      eventName: event.type,
      payload: event.toMap(),
    );
  }
}

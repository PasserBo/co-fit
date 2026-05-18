import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';
import '../data/room_event.dart';
import '../data/room_presence_member.dart';

const _defaultEventBufferLimit = 50;

class RoomBrowserState {
  const RoomBrowserState({
    this.joinedRoomIds = const <String>[],
    this.focusedRoomId,
    this.eventsByRoom = const <String, List<RoomEvent>>{},
    this.presenceByRoom = const <String, List<RoomPresenceMember>>{},
    this.isReady = false,
    this.error,
  });

  factory RoomBrowserState.initial() => const RoomBrowserState();

  final List<String> joinedRoomIds;
  final String? focusedRoomId;
  final Map<String, List<RoomEvent>> eventsByRoom;
  final Map<String, List<RoomPresenceMember>> presenceByRoom;
  final bool isReady;
  final String? error;

  RoomBrowserState copyWith({
    List<String>? joinedRoomIds,
    String? focusedRoomId,
    bool clearFocusedRoomId = false,
    Map<String, List<RoomEvent>>? eventsByRoom,
    Map<String, List<RoomPresenceMember>>? presenceByRoom,
    bool? isReady,
    String? error,
    bool clearError = false,
  }) {
    return RoomBrowserState(
      joinedRoomIds: joinedRoomIds ?? this.joinedRoomIds,
      focusedRoomId: clearFocusedRoomId
          ? null
          : (focusedRoomId ?? this.focusedRoomId),
      eventsByRoom: eventsByRoom ?? this.eventsByRoom,
      presenceByRoom: presenceByRoom ?? this.presenceByRoom,
      isReady: isReady ?? this.isReady,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RoomBrowserNotifier extends Notifier<RoomBrowserState> {
  final Map<String, StreamSubscription<RoomEvent>> _eventSubscriptions = {};
  final Map<String, StreamSubscription<List<RoomPresenceMember>>>
      _presenceSubscriptions = {};
  final Map<String, Set<String>> _seenEventIdsByRoom = {};

  @override
  RoomBrowserState build() {
    ref.onDispose(() {
      unawaited(_disposeSubscriptions());
    });
    return RoomBrowserState.initial();
  }

  Future<void> syncJoinedRooms(
    List<String> roomIds, {
    String? userId,
  }) async {
    final normalizedRoomIds = _normalizeRoomIds(roomIds);
    final previousIds = state.joinedRoomIds;
    final previousSet = previousIds.toSet();
    final nextSet = normalizedRoomIds.toSet();
    final added = nextSet.difference(previousSet);
    final removed = previousSet.difference(nextSet);

    for (final roomId in removed) {
      await _cancelRoomSubscriptions(roomId);
    }

    final nextFocused = _resolveFocusedRoomId(normalizedRoomIds);
    state = state.copyWith(
      joinedRoomIds: normalizedRoomIds,
      focusedRoomId: nextFocused,
      clearFocusedRoomId: nextFocused == null,
      isReady: true,
      clearError: true,
    );

    for (final roomId in added) {
      await _ensureActiveRoom(roomId: roomId, userId: userId);
    }
    for (final roomId in normalizedRoomIds) {
      await _ensureRoomStreams(roomId);
    }
  }

  void setFocusedRoom(String roomId) {
    final trimmed = roomId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (!state.joinedRoomIds.contains(trimmed)) {
      return;
    }
    state = state.copyWith(focusedRoomId: trimmed);
  }

  void ingestRoomEvent({
    required String roomId,
    required RoomEvent event,
  }) {
    final trimmedRoomId = roomId.trim();
    if (trimmedRoomId.isEmpty) {
      return;
    }
    final seenEventIds = _seenEventIdsByRoom.putIfAbsent(
      trimmedRoomId,
      () => <String>{},
    );
    if (!seenEventIds.add(event.eventId)) {
      return;
    }

    final currentEvents = state.eventsByRoom[trimmedRoomId] ?? const [];
    final nextEvents = <RoomEvent>[
      event,
      ...currentEvents,
    ].take(_defaultEventBufferLimit).toList(growable: false);

    final nextEventsByRoom = {
      ...state.eventsByRoom,
      trimmedRoomId: nextEvents,
    };
    state = state.copyWith(eventsByRoom: nextEventsByRoom);
  }

  void ingestPresence({
    required String roomId,
    required List<RoomPresenceMember> members,
  }) {
    final trimmedRoomId = roomId.trim();
    if (trimmedRoomId.isEmpty) {
      return;
    }
    final nextPresenceByRoom = {
      ...state.presenceByRoom,
      trimmedRoomId: List<RoomPresenceMember>.unmodifiable(members),
    };
    state = state.copyWith(presenceByRoom: nextPresenceByRoom);
  }

  Future<void> clear() async {
    await _disposeSubscriptions();
    _seenEventIdsByRoom.clear();
    state = RoomBrowserState.initial();
  }

  Future<void> _ensureActiveRoom({
    required String roomId,
    String? userId,
  }) async {
    final safeUserId = userId?.trim();
    if (safeUserId == null || safeUserId.isEmpty) {
      return;
    }
    try {
      await ref
          .read(ablyRuntimeProvider.notifier)
          .subscribeRoom(roomId: roomId, userId: safeUserId);
      await _ensureRoomStreams(roomId);
    } catch (error) {
      state = state.copyWith(error: 'Failed to activate room $roomId: $error');
    }
  }

  Future<void> _ensureRoomStreams(String roomId) async {
    if (!_eventSubscriptions.containsKey(roomId)) {
      final eventSubscription = ref
          .read(ablyRuntimeProvider.notifier)
          .watchRoomEvents(roomId: roomId)
          .listen(
            (event) => ingestRoomEvent(roomId: roomId, event: event),
            onError: (Object error) {
              state = state.copyWith(
                error: 'Event stream error ($roomId): $error',
              );
            },
          );
      _eventSubscriptions[roomId] = eventSubscription;
    }

    if (!_presenceSubscriptions.containsKey(roomId)) {
      final presenceSubscription = ref
          .read(ablyRuntimeProvider.notifier)
          .watchPresence(roomId: roomId)
          .listen(
            (members) => ingestPresence(roomId: roomId, members: members),
            onError: (Object error) {
              state = state.copyWith(
                error: 'Presence stream error ($roomId): $error',
              );
            },
          );
      _presenceSubscriptions[roomId] = presenceSubscription;
    }
  }

  Future<void> _cancelRoomSubscriptions(String roomId) async {
    await _eventSubscriptions.remove(roomId)?.cancel();
    await _presenceSubscriptions.remove(roomId)?.cancel();
    _seenEventIdsByRoom.remove(roomId);

    final nextEventsByRoom = Map<String, List<RoomEvent>>.from(state.eventsByRoom)
      ..remove(roomId);
    final nextPresenceByRoom =
        Map<String, List<RoomPresenceMember>>.from(state.presenceByRoom)
          ..remove(roomId);
    state = state.copyWith(
      eventsByRoom: nextEventsByRoom,
      presenceByRoom: nextPresenceByRoom,
    );
  }

  Future<void> _disposeSubscriptions() async {
    for (final subscription in _eventSubscriptions.values) {
      await subscription.cancel();
    }
    for (final subscription in _presenceSubscriptions.values) {
      await subscription.cancel();
    }
    _eventSubscriptions.clear();
    _presenceSubscriptions.clear();
  }

  String? _resolveFocusedRoomId(List<String> joinedRoomIds) {
    if (joinedRoomIds.isEmpty) {
      return null;
    }
    final currentFocused = state.focusedRoomId;
    if (currentFocused != null && joinedRoomIds.contains(currentFocused)) {
      return currentFocused;
    }
    return joinedRoomIds.first;
  }

  List<String> _normalizeRoomIds(List<String> roomIds) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final roomId in roomIds) {
      final trimmed = roomId.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      normalized.add(trimmed);
    }
    return List<String>.unmodifiable(normalized);
  }
}

final roomBrowserProvider =
    NotifierProvider<RoomBrowserNotifier, RoomBrowserState>(
      RoomBrowserNotifier.new,
    );

final focusedRoomEventsProvider = Provider<List<RoomEvent>>((ref) {
  return ref.watch(
    roomBrowserProvider.select((state) {
      final roomId = state.focusedRoomId;
      if (roomId == null) {
        return const <RoomEvent>[];
      }
      return state.eventsByRoom[roomId] ?? const <RoomEvent>[];
    }),
  );
});

final focusedRoomPresenceProvider = Provider<List<RoomPresenceMember>>((ref) {
  return ref.watch(
    roomBrowserProvider.select((state) {
      final roomId = state.focusedRoomId;
      if (roomId == null) {
        return const <RoomPresenceMember>[];
      }
      return state.presenceByRoom[roomId] ?? const <RoomPresenceMember>[];
    }),
  );
});

final roomEventsByIdProvider = Provider.family<List<RoomEvent>, String>((
  ref,
  roomId,
) {
  return ref.watch(
    roomBrowserProvider.select(
      (state) => state.eventsByRoom[roomId] ?? const <RoomEvent>[],
    ),
  );
});

final roomPresenceByIdProvider =
    Provider.family<List<RoomPresenceMember>, String>((ref, roomId) {
      return ref.watch(
        roomBrowserProvider.select(
          (state) => state.presenceByRoom[roomId] ?? const <RoomPresenceMember>[],
        ),
      );
    });

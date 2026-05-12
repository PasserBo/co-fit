import 'dart:async';

import 'package:flutter/material.dart';

import '../../../firestore/ably_service.dart';
import '../data/room_event.dart';
import '../data/room_presence_member.dart';
import '../data/room_realtime_repository.dart';
import '../usecase/connect_realtime_usecase.dart';
import '../usecase/disconnect_realtime_usecase.dart';
import '../usecase/join_room_usecase.dart';
import '../usecase/leave_room_usecase.dart';
import '../usecase/publish_room_event_usecase.dart';
import '../usecase/watch_connection_state_usecase.dart';
import '../usecase/watch_room_events_usecase.dart';
import '../usecase/watch_room_presence_usecase.dart';

class RoomMainPage extends StatefulWidget {
  const RoomMainPage({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  State<RoomMainPage> createState() => _RoomMainPageState();
}

class _RoomMainPageState extends State<RoomMainPage> {
  final _roomIdController = TextEditingController(text: 'main-room');
  final _seenEventIds = <String>{};
  final _actionOptions = const ['squat', 'plank', 'jumping_jack'];
  final _durationOptions = const [30, 60, 120];

  StreamSubscription<List<RoomPresenceMember>>? _presenceSubscription;
  StreamSubscription<RoomEvent>? _eventsSubscription;
  StreamSubscription<String>? _connectionSubscription;
  Timer? _timer;

  late final String _apiKey;
  late final bool _isConfigured;

  AblyService? _ablyService;
  RoomRealtimeRepository? _repository;
  ConnectRealtimeUsecase? _connectRealtimeUsecase;
  DisconnectRealtimeUsecase? _disconnectRealtimeUsecase;
  JoinRoomUsecase? _joinRoomUsecase;
  LeaveRoomUsecase? _leaveRoomUsecase;
  PublishRoomEventUsecase? _publishRoomEventUsecase;
  WatchConnectionStateUsecase? _watchConnectionStateUsecase;
  WatchRoomEventsUsecase? _watchRoomEventsUsecase;
  WatchRoomPresenceUsecase? _watchRoomPresenceUsecase;

  String _connectionState = 'disconnected';
  String? _activeRoomId;
  String _selectedAction = 'squat';
  int _selectedDurationSec = 30;
  int _remainingSec = 0;
  bool _isTimerRunning = false;
  bool _isJoining = false;
  String? _errorMessage;
  DateTime? _lastPublishedAt;

  List<RoomPresenceMember> _presenceMembers = const [];
  List<RoomEvent> _events = const [];

  bool get _isJoined => _activeRoomId != null;

  @override
  void initState() {
    super.initState();
    _apiKey = const String.fromEnvironment('ABLY_API_KEY');
    _isConfigured = _apiKey.isNotEmpty;

    if (!_isConfigured) {
      _errorMessage = 'Missing ABLY_API_KEY. Run with --dart-define=ABLY_API_KEY=...';
      return;
    }

    final clientIdPrefix = const String.fromEnvironment(
      'ABLY_CLIENT_ID_PREFIX',
      defaultValue: 'cofit',
    );
    final clientId = '$clientIdPrefix-${widget.userId}';
    _ablyService = AblyService(apiKey: _apiKey, clientId: clientId);
    _repository = RoomRealtimeRepository(_ablyService!);
    _connectRealtimeUsecase = ConnectRealtimeUsecase(_repository!);
    _disconnectRealtimeUsecase = DisconnectRealtimeUsecase(_repository!);
    _joinRoomUsecase = JoinRoomUsecase(_repository!);
    _leaveRoomUsecase = LeaveRoomUsecase(_repository!);
    _publishRoomEventUsecase = PublishRoomEventUsecase(_repository!);
    _watchConnectionStateUsecase = WatchConnectionStateUsecase(_repository!);
    _watchRoomEventsUsecase = WatchRoomEventsUsecase(_repository!);
    _watchRoomPresenceUsecase = WatchRoomPresenceUsecase(_repository!);

    unawaited(_connectRealtimeUsecase!.execute());
    _connectionSubscription = _watchConnectionStateUsecase!.execute().listen((
      state,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionState = state;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _presenceSubscription?.cancel();
    _eventsSubscription?.cancel();
    _connectionSubscription?.cancel();
    if (_isJoined && _leaveRoomUsecase != null) {
      unawaited(_leaveRoomUsecase!.execute(roomId: _activeRoomId!));
    }
    if (_disconnectRealtimeUsecase != null) {
      unawaited(_disconnectRealtimeUsecase!.execute());
    }
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (!_isConfigured || _joinRoomUsecase == null) {
      return;
    }

    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _errorMessage = 'roomId is required';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      if (_isJoined) {
        await _leaveRoom();
      }
      await _joinRoomUsecase!.execute(roomId: roomId, userId: widget.userId);

      await _presenceSubscription?.cancel();
      await _eventsSubscription?.cancel();

      _presenceSubscription = _watchRoomPresenceUsecase!
          .execute(roomId: roomId)
          .listen((members) {
            if (!mounted) {
              return;
            }
            setState(() {
              _presenceMembers = members;
            });
          });

      _eventsSubscription = _watchRoomEventsUsecase!.execute(roomId: roomId).listen(
        (event) {
          if (_seenEventIds.contains(event.eventId)) {
            return;
          }
          _seenEventIds.add(event.eventId);
          if (!mounted) {
            return;
          }
          setState(() {
            _events = [event, ..._events].take(100).toList(growable: false);
          });
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _errorMessage = 'Event stream error: $error';
          });
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _activeRoomId = roomId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to join room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leaveRoom() async {
    if (!_isJoined || _leaveRoomUsecase == null) {
      return;
    }

    final roomId = _activeRoomId!;
    _timer?.cancel();
    _isTimerRunning = false;
    _remainingSec = 0;
    await _leaveRoomUsecase!.execute(roomId: roomId);
    await _presenceSubscription?.cancel();
    await _eventsSubscription?.cancel();
    _presenceSubscription = null;
    _eventsSubscription = null;

    if (!mounted) {
      return;
    }
    setState(() {
      _activeRoomId = null;
      _presenceMembers = const [];
      _events = const [];
      _seenEventIds.clear();
    });
  }

  Future<void> _publishActionEvent(RoomEventType type) async {
    if (!_isJoined || _publishRoomEventUsecase == null) {
      return;
    }

    final now = DateTime.now();
    if (_lastPublishedAt != null &&
        now.difference(_lastPublishedAt!).inMilliseconds < 250) {
      return;
    }
    _lastPublishedAt = now;

    final roomId = _activeRoomId!;
    final event = RoomEvent(
      eventId: '${widget.userId}-${now.microsecondsSinceEpoch}',
      roomId: roomId,
      userId: widget.userId,
      type: type,
      timestamp: now,
      payload: {
        'actionKey': _selectedAction,
        'durationSec': _selectedDurationSec,
        'remainingSec': _remainingSec,
      },
    );

    try {
      await _publishRoomEventUsecase!.execute(event: event);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to publish event: $error';
      });
    }
  }

  Future<void> _startAction() async {
    setState(() {
      _remainingSec = _selectedDurationSec;
      _isTimerRunning = true;
    });
    _startTimer();
    await _publishActionEvent(RoomEventType.actionStarted);
  }

  Future<void> _pauseAction() async {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
    await _publishActionEvent(RoomEventType.actionPaused);
  }

  Future<void> _resumeAction() async {
    if (_remainingSec <= 0) {
      return;
    }
    setState(() {
      _isTimerRunning = true;
    });
    _startTimer();
    await _publishActionEvent(RoomEventType.actionResumed);
  }

  Future<void> _completeAction() async {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSec = 0;
    });
    await _publishActionEvent(RoomEventType.actionCompleted);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSec <= 1) {
        timer.cancel();
        unawaited(_completeAction());
        return;
      }
      setState(() {
        _remainingSec -= 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Event-First Room Console',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection: $_connectionState'),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomIdController,
                  enabled: !_isJoining,
                  decoration: const InputDecoration(
                    labelText: 'roomId',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isJoining || !_isConfigured ? null : _joinRoom,
                        child: Text(_isJoined ? 'Switch Room' : 'Join Room'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isJoined ? _leaveRoom : null,
                        child: const Text('Leave Room'),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Event Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAction,
                  items: _actionOptions
                      .map((action) => DropdownMenuItem(
                            value: action,
                            child: Text(action),
                          ))
                      .toList(growable: false),
                  onChanged: _isJoined
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedAction = value;
                          });
                        }
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedDurationSec,
                  items: _durationOptions
                      .map((duration) => DropdownMenuItem(
                            value: duration,
                            child: Text('$duration sec'),
                          ))
                      .toList(growable: false),
                  onChanged: _isJoined
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedDurationSec = value;
                          });
                        }
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Remaining: $_remainingSec sec',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _isJoined ? _startAction : null,
                      child: const Text('Start'),
                    ),
                    OutlinedButton(
                      onPressed: _isJoined && _isTimerRunning ? _pauseAction : null,
                      child: const Text('Pause'),
                    ),
                    OutlinedButton(
                      onPressed: _isJoined && !_isTimerRunning && _remainingSec > 0
                          ? _resumeAction
                          : null,
                      child: const Text('Resume'),
                    ),
                    OutlinedButton(
                      onPressed: _isJoined ? _completeAction : null,
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Members (${_presenceMembers.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_presenceMembers.isEmpty)
                  const Text('No members online yet.')
                else
                  ..._presenceMembers.map((member) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(member.userId),
                      subtitle: Text('clientId: ${member.clientId}'),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Timeline (${_events.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_events.isEmpty)
                  const Text('No events received yet.')
                else
                  ..._events.take(30).map((event) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_outlined),
                      title: Text('${event.userId} -> ${event.type.value}'),
                      subtitle: Text(
                        '${event.timestamp.toIso8601String()} | '
                        'action=${event.payload['actionKey']} '
                        'remaining=${event.payload['remainingSec']}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

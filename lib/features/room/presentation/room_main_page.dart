import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/user_bootstrap_provider.dart';
import '../data/room_repository_provider.dart';
import '../../../firestore/ably_state_machine.dart';
import '../data/room_event.dart';
import '../data/room_presence_member.dart';
import 'room_create_page.dart';

class RoomMainPage extends ConsumerStatefulWidget {
  const RoomMainPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<RoomMainPage> createState() => _RoomMainPageState();
}

class _RoomMainPageState extends ConsumerState<RoomMainPage> {
  final _roomIdController = TextEditingController(text: 'main-room');
  final _seenEventIds = <String>{};
  final _actionOptions = const ['squat', 'plank', 'jumping_jack'];
  final _durationOptions = const [30, 60, 120];

  StreamSubscription<List<RoomPresenceMember>>? _presenceSubscription;
  StreamSubscription<RoomEvent>? _eventsSubscription;
  Timer? _timer;

  String? _activeRoomId;
  String _selectedAction = 'squat';
  int _selectedDurationSec = 30;
  int _remainingSec = 0;
  bool _isTimerRunning = false;
  bool _isJoining = false;
  String? _errorMessage;
  DateTime? _lastPublishedAt;
  String? _activeSessionId;

  List<RoomPresenceMember> _presenceMembers = const [];
  List<RoomEvent> _events = const [];

  bool get _isJoined => _activeRoomId != null;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(ablyRuntimeProvider.notifier).initializeForUser(widget.userId),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _presenceSubscription?.cancel();
    _eventsSubscription?.cancel();
    if (_isJoined) {
      unawaited(
        ref
            .read(ablyRuntimeProvider.notifier)
            .leaveRoom(roomId: _activeRoomId!),
      );
    }
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _subscribeRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _errorMessage = 'roomId is required';
      });
      return;
    }
    await _subscribeRoomById(roomId);
  }

  Future<void> _subscribeRoomById(String roomId) async {
    final runtime = ref.read(ablyRuntimeProvider);
    if (!runtime.isConfigured) {
      setState(() {
        _errorMessage = runtime.lastError ?? 'Ably is not configured.';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
      _roomIdController.text = roomId;
    });

    try {
      final notifier = ref.read(ablyRuntimeProvider.notifier);
      if (_isJoined) {
        await _leaveRoom();
      }
      await notifier.subscribeRoom(roomId: roomId, userId: widget.userId);

      await _presenceSubscription?.cancel();
      await _eventsSubscription?.cancel();

      _presenceSubscription = notifier.watchPresence(roomId: roomId).listen((
        members,
      ) {
        if (!mounted) {
          return;
        }
        setState(() {
          _presenceMembers = members;
        });
      });

      _eventsSubscription = notifier
          .watchRoomEvents(roomId: roomId)
          .listen(
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
        _errorMessage = 'Failed to subscribe room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _joinAndSubscribeRoom() async {
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
      final roomRepository = ref.read(firebaseRoomRepositoryProvider);
      await roomRepository.joinRoomWithMembership(
        roomId: roomId,
        userId: widget.userId,
      );
      await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
      await _subscribeRoomById(roomId);
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
    if (!_isJoined) {
      return;
    }

    final roomId = _activeRoomId!;
    _timer?.cancel();
    _isTimerRunning = false;
    _remainingSec = 0;
    await ref.read(ablyRuntimeProvider.notifier).leaveRoom(roomId: roomId);
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

  Future<void> _publishActionEvent(String type) async {
    if (!_isJoined) {
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
      payload: RoomEventPayload(
        schemaVersion: 1,
        actionKey: _selectedAction,
        durationSec: _selectedDurationSec,
        remainingSec: _remainingSec,
        sessionId:
            _activeSessionId ??
            '${widget.userId}-${now.millisecondsSinceEpoch}',
        customData: const {},
      ),
    );

    try {
      await ref
          .read(ablyRuntimeProvider.notifier)
          .publishRoomEvent(event: event);
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
    final now = DateTime.now();
    setState(() {
      _activeSessionId = '${widget.userId}-${now.millisecondsSinceEpoch}';
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
    if (mounted) {
      setState(() {
        _activeSessionId = null;
      });
    }
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
    final runtime = ref.watch(ablyRuntimeProvider);
    final userBootstrapState = ref.watch(userBootstrapProvider);
    final joinedRoomIds = userBootstrapState.joinedRoomIds;
    final roomChannelState = _activeRoomId == null
        ? null
        : runtime.channelStates[_activeRoomId!];
    final effectiveError =
        _errorMessage ?? userBootstrapState.error ?? runtime.lastError;
    final connectionLabel = _connectionLabel(runtime);
    final connectionColor = _connectionColor(runtime, context);
    final channelLabel = _channelLabel(roomChannelState);
    final channelColor = _channelColor(roomChannelState, context);

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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      label: 'Ably: $connectionLabel',
                      color: connectionColor,
                    ),
                    _statusChip(
                      label: 'Room Channel: $channelLabel',
                      color: channelColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Joined Rooms (${joinedRoomIds.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (userBootstrapState.isBootstrapping)
                  const LinearProgressIndicator()
                else if (joinedRoomIds.isEmpty)
                  const Text(
                    'No joined rooms yet. Use manual roomId fallback below.',
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: joinedRoomIds
                        .map(
                          (roomId) => ActionChip(
                            avatar: const Icon(Icons.meeting_room_outlined, size: 16),
                            label: Text(roomId),
                            onPressed: _isJoining
                                ? null
                                : () => unawaited(_subscribeRoomById(roomId)),
                          ),
                        )
                        .toList(growable: false),
                  ),
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
                        onPressed: _isJoining || !runtime.isConfigured
                            ? null
                            : _subscribeRoom,
                        child: Text(
                          _isJoined ? 'Switch Subscription' : 'Subscribe Room',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isJoining ? null : _joinAndSubscribeRoom,
                        child: const Text('Join & Subscribe'),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RoomCreatePage(userId: widget.userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Room'),
                ),
                if (effectiveError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    effectiveError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                      .map(
                        (action) => DropdownMenuItem(
                          value: action,
                          child: Text(action),
                        ),
                      )
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
                      .map(
                        (duration) => DropdownMenuItem(
                          value: duration,
                          child: Text('$duration sec'),
                        ),
                      )
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
                      onPressed: _isJoined && _isTimerRunning
                          ? _pauseAction
                          : null,
                      child: const Text('Pause'),
                    ),
                    OutlinedButton(
                      onPressed:
                          _isJoined && !_isTimerRunning && _remainingSec > 0
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
        ),
      ],
    );
  }

  String _connectionLabel(AblyRuntimeState runtime) {
    switch (runtime.runtimePhase) {
      case AblyRuntimePhase.idle:
        return 'idle';
      case AblyRuntimePhase.unconfigured:
        return 'unconfigured';
      case AblyRuntimePhase.active:
        final state = runtime.connectionState;
        if (state == null) {
          return 'unknown';
        }
        return state.name;
    }
  }

  Color _connectionColor(AblyRuntimeState runtime, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (runtime.runtimePhase == AblyRuntimePhase.unconfigured) {
      return scheme.error;
    }
    final state = runtime.connectionState;
    if (state == ably.ConnectionState.connected) {
      return Colors.green;
    }
    if (state == ably.ConnectionState.connecting) {
      return Colors.orange;
    }
    if (state == ably.ConnectionState.disconnected) {
      return Colors.orange;
    }
    if (state == ably.ConnectionState.failed) {
      return scheme.error;
    }
    return Colors.blueGrey;
  }

  String _channelLabel(ably.ChannelState? state) {
    if (_activeRoomId == null) {
      return 'n/a';
    }
    return state?.name ?? 'unknown';
  }

  Color _channelColor(ably.ChannelState? state, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_activeRoomId == null) {
      return Colors.blueGrey;
    }
    if (state == ably.ChannelState.attached) {
      return Colors.green;
    }
    if (state == ably.ChannelState.attaching ||
        state == ably.ChannelState.detaching) {
      return Colors.orange;
    }
    if (state == ably.ChannelState.failed) {
      return scheme.error;
    }
    return Colors.blueGrey;
  }

  Widget _statusChip({required String label, required Color color}) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text(label),
    );
  }
}

import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/room/domain/entity/room_event.dart';
import '../features/room/domain/entity/room_presence_member.dart';
import '../features/room/domain/entity/user_activity_status_entity.dart';
import '../features/room/data/room_realtime_repository.dart';
import '../features/room/provider/own_activity_status_provider.dart';
import '../features/room/provider/own_nickname_provider.dart';
import 'ably_service.dart';

enum AblyRuntimePhase {
  idle,
  unconfigured,
  active,
}

class AblyRuntimeState {
  const AblyRuntimeState({
    required this.isConfigured,
    required this.runtimePhase,
    required this.connectionState,
    required this.channelStates,
    this.clientId,
    this.lastError,
  });

  factory AblyRuntimeState.initial() {
    return const AblyRuntimeState(
      isConfigured: true,
      runtimePhase: AblyRuntimePhase.idle,
      connectionState: null,
      channelStates: <String, ably.ChannelState>{},
    );
  }

  final bool isConfigured;
  final AblyRuntimePhase runtimePhase;
  final ably.ConnectionState? connectionState;
  final Map<String, ably.ChannelState> channelStates;
  final String? clientId;
  final String? lastError;

  AblyRuntimeState copyWith({
    bool? isConfigured,
    AblyRuntimePhase? runtimePhase,
    ably.ConnectionState? connectionState,
    Map<String, ably.ChannelState>? channelStates,
    String? clientId,
    String? lastError,
    bool clearConnectionState = false,
    bool clearError = false,
  }) {
    return AblyRuntimeState(
      isConfigured: isConfigured ?? this.isConfigured,
      runtimePhase: runtimePhase ?? this.runtimePhase,
      connectionState: clearConnectionState
          ? null
          : (connectionState ?? this.connectionState),
      channelStates: channelStates ?? this.channelStates,
      clientId: clientId ?? this.clientId,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class AblyRuntimeNotifier extends Notifier<AblyRuntimeState> {
  String? _boundUserId;
  AblyService? _ablyService;
  RoomRealtimeRepository? _repository;
  StreamSubscription<ably.ConnectionStateChange>? _connectionSubscription;
  final Map<String, StreamSubscription<ably.ChannelStateChange>>
      _channelSubscriptions = {};

  @override
  AblyRuntimeState build() {
    ref.onDispose(_disposeInternals);
    return AblyRuntimeState.initial();
  }

  Future<void> initializeForUser(String userId) async {
    if (_boundUserId == userId && _repository != null) {
      return;
    }

    await _disposeInternals();

    final apiKey = const String.fromEnvironment('ABLY_API_KEY');
    if (apiKey.isEmpty) {
      state = state.copyWith(
        isConfigured: false,
        runtimePhase: AblyRuntimePhase.unconfigured,
        clearConnectionState: true,
        channelStates: const {},
        lastError: 'Missing ABLY_API_KEY in dart-define environment',
      );
      return;
    }

    final clientIdPrefix = const String.fromEnvironment(
      'ABLY_CLIENT_ID_PREFIX',
      defaultValue: 'cofit',
    );
    final clientId = '$clientIdPrefix-$userId';

    final service = AblyService(apiKey: apiKey, clientId: clientId);
    _ablyService = service;
    _repository = RoomRealtimeRepository(service);
    _boundUserId = userId;

    state = state.copyWith(
      isConfigured: true,
      runtimePhase: AblyRuntimePhase.active,
      clientId: clientId,
      connectionState: ably.ConnectionState.connecting,
      channelStates: const {},
      clearError: true,
    );

    _connectionSubscription = service.watchConnectionState().listen((change) {
      state = state.copyWith(
        connectionState: change.current,
      );
    });

    await _repository!.connect();
  }

  Future<void> subscribeRoom({
    required String roomId,
    required String userId,
  }) async {
    await initializeForUser(userId);
    if (_repository == null) {
      return;
    }

    await _ensureRoomChannelWatched(roomId);
    // 运动中途进入新房间时带上 activity(enter 整包写 data,不带会显示 idle)。
    await _repository!.subscribeRoom(
      roomId: roomId,
      userId: userId,
      nickname: ref.read(ownNicknameProvider),
      activity: _currentActivityMap(),
    );
  }

  /// 当前自己的 activity 快照(重申到 now);idle 时返回 null。
  Map<String, dynamic>? _currentActivityMap() {
    final status = ref.read(ownActivityStatusProvider);
    if (status == null) {
      return null;
    }
    final refreshed = reassertActivityStatusAt(status, DateTime.now());
    if (refreshed.activityState == UserActivityState.idle) {
      return null;
    }
    return userActivityStatusEntityToMap(refreshed);
  }

  Future<void> leaveRoom({
    required String roomId,
  }) async {
    if (_repository == null) {
      return;
    }
    await _repository!.leaveRoom(roomId: roomId);
  }

  Future<void> publishRoomEvent({
    required RoomEvent event,
  }) async {
    if (_repository == null) {
      return;
    }
    await _ensureRoomChannelWatched(event.roomId);
    await _repository!.publishEvent(event: event);
  }

  Future<void> updatePresenceData({
    required String roomId,
    required Map<String, dynamic> data,
  }) async {
    if (_repository == null) {
      return;
    }
    await _ensureRoomChannelWatched(roomId);
    await _repository!.updatePresenceData(roomId: roomId, data: data);
  }

  Stream<List<RoomPresenceMember>> watchPresence({
    required String roomId,
  }) {
    if (_repository == null) {
      return const Stream.empty();
    }
    return _repository!.watchPresence(roomId: roomId);
  }

  Stream<RoomEvent> watchRoomEvents({
    required String roomId,
  }) {
    if (_repository == null) {
      return const Stream.empty();
    }
    return _repository!.watchRoomEvents(roomId: roomId);
  }

  Future<void> onAppResumed() async {
    if (_repository == null) {
      return;
    }
    final current = state.connectionState;
    if (current != ably.ConnectionState.connected &&
        current != ably.ConnectionState.connecting) {
      await _repository!.connect();
    }
    await _reassertPresence();
  }

  /// 回前台后对所有已订阅房间重申 presence:
  /// - 运动中:activity 刷新 updatedAtEpochMs(接收端严格更新检查,旧时间戳会被丢弃);
  ///   已到点则重申 idle(本地计时器随后会补发 completed 事件)。
  /// - idle:重申 `{userId, activity: idle}`,清掉后台期间可能残留的旧 active 快照。
  Future<void> _reassertPresence() async {
    final repository = _repository;
    final userId = _boundUserId;
    if (repository == null || userId == null) {
      return;
    }
    final status = ref.read(ownActivityStatusProvider);
    final now = DateTime.now();
    final refreshed = reassertActivityStatusAt(
      status ?? UserActivityStatusEntity.idle(),
      now,
    );
    final nickname = ref.read(ownNicknameProvider);
    final data = <String, dynamic>{
      'userId': userId,
      'nickname': ?nickname,
      'activity': userActivityStatusEntityToMap(refreshed),
    };
    for (final roomId in _channelSubscriptions.keys.toList()) {
      try {
        await repository.updatePresenceData(roomId: roomId, data: data);
      } catch (_) {
        // 单房间重申失败不阻塞其余房间;连接层错误由 connectionState 呈现。
      }
    }
  }

  /// 登出时调用:逐房间退出 presence 后释放连接,并复位状态。
  Future<void> shutdown() async {
    final repository = _repository;
    if (repository != null) {
      for (final roomId in _channelSubscriptions.keys.toList()) {
        try {
          await repository.leaveRoom(roomId: roomId);
        } catch (_) {
          // 尽力而为:离线时 leave 失败靠 Ably presence 超时兜底。
        }
      }
    }
    await _disposeInternals();
    state = AblyRuntimeState.initial();
  }

  Future<void> _ensureRoomChannelWatched(String roomId) async {
    if (_ablyService == null || _channelSubscriptions.containsKey(roomId)) {
      return;
    }
    final initial = _ablyService!.getRoomChannelState(roomId);
    state = state.copyWith(
      channelStates: {
        ...state.channelStates,
        roomId: initial,
      },
    );

    final subscription = _ablyService!
        .watchRoomChannelState(roomId: roomId)
        .listen((channelState) {
      final nextStates = {
        ...state.channelStates,
        roomId: channelState.current,
      };
      state = state.copyWith(channelStates: nextStates);
    });
    _channelSubscriptions[roomId] = subscription;
  }

  Future<void> _disposeInternals() async {
    for (final sub in _channelSubscriptions.values) {
      await sub.cancel();
    }
    _channelSubscriptions.clear();
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _ablyService?.dispose();
    _ablyService = null;
    _repository = null;
    _boundUserId = null;
  }
}

final ablyRuntimeProvider =
    NotifierProvider<AblyRuntimeNotifier, AblyRuntimeState>(
  AblyRuntimeNotifier.new,
);

class AblyLifecycleBinder extends ConsumerStatefulWidget {
  const AblyLifecycleBinder({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<AblyLifecycleBinder> createState() => _AblyLifecycleBinderState();
}

class _AblyLifecycleBinderState extends ConsumerState<AblyLifecycleBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(ablyRuntimeProvider.notifier).onAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

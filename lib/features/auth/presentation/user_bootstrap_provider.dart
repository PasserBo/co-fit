import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../room/data/room_repository_provider.dart';
import '../../../firestore/ably_state_machine.dart';

class UserBootstrapState {
  const UserBootstrapState({
    this.userId,
    this.joinedRoomIds = const <String>[],
    this.isBootstrapping = false,
    this.error,
  });

  factory UserBootstrapState.initial() => const UserBootstrapState();

  final String? userId;
  final List<String> joinedRoomIds;
  final bool isBootstrapping;
  final String? error;

  UserBootstrapState copyWith({
    String? userId,
    List<String>? joinedRoomIds,
    bool? isBootstrapping,
    String? error,
    bool clearError = false,
  }) {
    return UserBootstrapState(
      userId: userId ?? this.userId,
      joinedRoomIds: joinedRoomIds ?? this.joinedRoomIds,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserBootstrapNotifier extends Notifier<UserBootstrapState> {
  String? _lastBootstrappedUserId;
  Future<void>? _runningBootstrapFuture;
  String? _runningBootstrapUserId;

  @override
  UserBootstrapState build() => UserBootstrapState.initial();

  Future<void> bootstrap(String userId) async {
    if (_runningBootstrapFuture != null && _runningBootstrapUserId == userId) {
      return _runningBootstrapFuture!;
    }
    if (_lastBootstrappedUserId == userId) {
      return;
    }

    final task = _runBootstrap(userId);
    _runningBootstrapFuture = task;
    _runningBootstrapUserId = userId;
    try {
      await task;
    } finally {
      if (identical(_runningBootstrapFuture, task)) {
        _runningBootstrapFuture = null;
        _runningBootstrapUserId = null;
      }
    }
  }

  Future<void> _runBootstrap(String userId) async {
    state = state.copyWith(
      userId: userId,
      isBootstrapping: true,
      clearError: true,
    );

    try {
      final ablyRuntime = ref.read(ablyRuntimeProvider.notifier);
      await ablyRuntime.initializeForUser(userId);

      final roomRepository = ref.read(firebaseRoomRepositoryProvider);
      final joinedRoomIds = await roomRepository.fetchJoinedRoomIds(
        userId: userId,
      );
      for (final roomId in joinedRoomIds) {
        await ablyRuntime.subscribeRoom(roomId: roomId, userId: userId);
      }

      _lastBootstrappedUserId = userId;
      state = state.copyWith(
        userId: userId,
        joinedRoomIds: joinedRoomIds,
        isBootstrapping: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        userId: userId,
        isBootstrapping: false,
        error: error.toString(),
      );
    }
  }

  Future<void> refreshJoinedRooms() async {
    final userId = state.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    final roomRepository = ref.read(firebaseRoomRepositoryProvider);
    final joinedRoomIds = await roomRepository.fetchJoinedRoomIds(
      userId: userId,
    );
    state = state.copyWith(joinedRoomIds: joinedRoomIds);
  }

  void clear() {
    _lastBootstrappedUserId = null;
    _runningBootstrapFuture = null;
    _runningBootstrapUserId = null;
    state = UserBootstrapState.initial();
  }
}

final userBootstrapProvider =
    NotifierProvider<UserBootstrapNotifier, UserBootstrapState>(
      UserBootstrapNotifier.new,
    );

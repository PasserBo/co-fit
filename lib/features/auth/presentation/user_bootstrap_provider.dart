import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../room/data/room_repository_provider.dart';
import '../../room/presentation/room_browser_provider.dart';
import '../../room/provider/own_activity_status_provider.dart';
import '../../../firestore/ably_state_machine.dart';
import '../../action/domain/entity/action_template_card.dart';
import '../../action/presentation/action_template_usecase_provider.dart';
import '../../action/provider/action_decks_provider.dart';
import '../../action/provider/own_action_session_notifier.dart';

/// 启动数据加载的阶段(splash 文案与首屏放行的依据)。
///
/// 新增「首屏之前必须做完」的任务(离线期间的数据变更同步、版本迁移、
/// 远端配置预热……)时:加一个阶段 + 在 [UserBootstrapNotifier._runBootstrap]
/// 里按顺序追加一步即可,AuthGate 不用改。
enum UserBootstrapPhase {
  idle,
  connecting,
  loadingRooms,
  loadingCards,
  restoringSession,
  ready,
  failed;

  /// 加载流程已结束(成功或失败),可以放行首屏。
  bool get isSettled => this == ready || this == failed;
}

extension UserBootstrapPhaseLabel on UserBootstrapPhase {
  /// splash 上的阶段文案。
  String get splashLabel => switch (this) {
    UserBootstrapPhase.idle || UserBootstrapPhase.connecting => '正在连接…',
    UserBootstrapPhase.loadingRooms => '正在加载房间…',
    UserBootstrapPhase.loadingCards => '正在整理卡牌…',
    UserBootstrapPhase.restoringSession => '正在恢复运动…',
    UserBootstrapPhase.ready => '准备就绪',
    UserBootstrapPhase.failed => '连接遇到问题,先进入看看',
  };
}

class UserBootstrapState {
  const UserBootstrapState({
    this.userId,
    this.joinedRoomIds = const <String>[],
    this.isBootstrapping = false,
    this.phase = UserBootstrapPhase.idle,
    this.isGateOpen = false,
    this.error,
  });

  factory UserBootstrapState.initial() => const UserBootstrapState();

  final String? userId;
  final List<String> joinedRoomIds;
  final bool isBootstrapping;
  final UserBootstrapPhase phase;

  /// 首屏是否可以放行(替代 splash)。流程结束即放行;
  /// 流程卡住(弱网下 Firestore 读取迟迟不返回)时到 [UserBootstrapNotifier.gateTimeout]
  /// 也放行,剩余步骤在后台继续,结果到了再刷新。
  final bool isGateOpen;
  final String? error;

  UserBootstrapState copyWith({
    String? userId,
    List<String>? joinedRoomIds,
    bool? isBootstrapping,
    UserBootstrapPhase? phase,
    bool? isGateOpen,
    String? error,
    bool clearError = false,
  }) {
    return UserBootstrapState(
      userId: userId ?? this.userId,
      joinedRoomIds: joinedRoomIds ?? this.joinedRoomIds,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      phase: phase ?? this.phase,
      isGateOpen: isGateOpen ?? this.isGateOpen,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserBootstrapNotifier extends Notifier<UserBootstrapState> {
  /// 首屏放行的兜底时限:超过就不再让用户盯着 splash,后台继续加载。
  static const gateTimeout = Duration(seconds: 8);

  String? _lastBootstrappedUserId;
  Future<void>? _runningBootstrapFuture;
  String? _runningBootstrapUserId;
  Timer? _gateTimer;

  @override
  UserBootstrapState build() {
    ref.onDispose(() => _gateTimer?.cancel());
    return UserBootstrapState.initial();
  }

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

  void _setPhase(UserBootstrapPhase phase) {
    state = state.copyWith(phase: phase);
  }

  void _armGateTimer(String userId) {
    _gateTimer?.cancel();
    _gateTimer = Timer(gateTimeout, () {
      if (state.userId == userId && !state.isGateOpen) {
        debugPrint('bootstrap gate timed out at ${state.phase}; releasing UI');
        state = state.copyWith(isGateOpen: true);
      }
    });
  }

  Future<void> _runBootstrap(String userId) async {
    state = state.copyWith(
      userId: userId,
      isBootstrapping: true,
      phase: UserBootstrapPhase.connecting,
      isGateOpen: false,
      clearError: true,
    );
    _armGateTimer(userId);

    try {
      // 1. 实时连接
      final ablyRuntime = ref.read(ablyRuntimeProvider.notifier);
      await ablyRuntime.initializeForUser(userId);

      // 2. 已加入房间:拉取 → 逐个订阅 → 同步到房间浏览器状态
      //    (首屏「没有加入任何房间」空态只能在这一步之后才算数)
      _setPhase(UserBootstrapPhase.loadingRooms);
      final roomRepository = ref.read(firebaseRoomRepositoryProvider);
      final joinedRoomIds = await roomRepository.fetchJoinedRoomIds(
        userId: userId,
      );
      for (final roomId in joinedRoomIds) {
        await ablyRuntime.subscribeRoom(roomId: roomId, userId: userId);
      }

      _lastBootstrappedUserId = userId;
      await ref
          .read(roomBrowserProvider.notifier)
          .syncJoinedRooms(joinedRoomIds, userId: userId);
      state = state.copyWith(joinedRoomIds: joinedRoomIds);

      // 3. 卡牌与牌组预热:首帧扇形手牌就是完整的,不再从空扇形闪成有牌。
      //    失败不阻塞(页面自己会重试加载)。
      _setPhase(UserBootstrapPhase.loadingCards);
      List<ActionTemplateCard>? warmedCards;
      try {
        warmedCards = await ref.read(templateCardsProvider.future);
        await ref.read(actionDecksProvider.future);
        await ref.read(activeDeckIdProvider.future);
      } catch (error) {
        debugPrint('bootstrap card warm-up failed: $error');
      }

      // 4. 上次会话中被杀的补记/恢复;失败不阻塞 bootstrap。
      _setPhase(UserBootstrapPhase.restoringSession);
      try {
        final List<ActionTemplateCard> cards =
            warmedCards ?? (await ref.read(templateCardsProvider.future));
        await ref
            .read(ownActionSessionProvider.notifier)
            .recoverPending(userId: userId, cards: cards);
      } catch (error) {
        debugPrint('recoverPending failed: $error');
      }

      _gateTimer?.cancel();
      state = state.copyWith(
        userId: userId,
        joinedRoomIds: joinedRoomIds,
        isBootstrapping: false,
        phase: UserBootstrapPhase.ready,
        isGateOpen: true,
        clearError: true,
      );
    } catch (error) {
      _gateTimer?.cancel();
      state = state.copyWith(
        userId: userId,
        isBootstrapping: false,
        phase: UserBootstrapPhase.failed,
        isGateOpen: true,
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
    await ref
        .read(roomBrowserProvider.notifier)
        .syncJoinedRooms(joinedRoomIds, userId: userId);
    state = state.copyWith(joinedRoomIds: joinedRoomIds);
  }

  void clear() {
    _gateTimer?.cancel();
    _lastBootstrappedUserId = null;
    _runningBootstrapFuture = null;
    _runningBootstrapUserId = null;
    // 登出:退出所有房间 presence 并释放 Ably 连接,清空自己的 activity 快照。
    ref.read(ownActivityStatusProvider.notifier).set(null);
    unawaited(ref.read(ablyRuntimeProvider.notifier).shutdown());
    unawaited(ref.read(roomBrowserProvider.notifier).clear());
    state = UserBootstrapState.initial();
  }
}

final userBootstrapProvider =
    NotifierProvider<UserBootstrapNotifier, UserBootstrapState>(
      UserBootstrapNotifier.new,
    );

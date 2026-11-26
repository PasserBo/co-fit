import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/cofit_confirm_sheet.dart';
import '../../../../core/widget/floating_dock.dart';
import '../../../action/domain/entity/action_deck.dart';
import '../../../action/domain/entity/action_template_card.dart';
import '../../../action/presentation/widget/card_fan.dart';
import '../../../action/presentation/widget/deck_switcher.dart';
import '../../../action/provider/action_deck_repository_provider.dart';
import '../../../action/provider/action_decks_provider.dart';
import '../../../action/provider/own_action_session_notifier.dart';
import '../../../auth/presentation/user_bootstrap_provider.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';
import '../../../avatar/presentation/renderer/avatar_renderer.dart';
import '../../../avatar/provider/avatar_renderer_provider.dart';
import '../../../../firestore/ably_state_machine.dart';
import '../../../home_sheet/domain/stage_rules.dart';
import '../../../home_sheet/presentation/module/home_sheet_module.dart';
import '../../../home_sheet/provider/home_sheet_providers.dart';
import '../../../home_sheet/usecase/auto_expand_policy.dart';
import '../../../home_sheet/presentation/stage/home_stage_controller.dart';
import '../../../home_sheet/presentation/widget/home_sheet_debug_module.dart';
import '../../../home_sheet/presentation/widget/home_sheet_panel.dart';
import '../../../home_sheet/presentation/widget/stage_avatar_layer.dart';
import '../../domain/entity/room_presence_member.dart';
import '../../domain/entity/user_activity_status_entity.dart';
import '../../provider/room_connection_status_provider.dart';
import '../../provider/own_activity_status_provider.dart';
import '../../provider/member_nickname_provider.dart';
import '../../provider/own_nickname_provider.dart';
import '../../provider/room_info_provider.dart';
import '../../../invite/provider/invite_usecase_providers.dart';
import '../join_room_provider.dart';
import '../room_browser_provider.dart';
import '../widget/dissolve_room_dialog.dart';
import '../widget/activity_hud.dart';
import '../widget/avatar_bubble.dart';
import '../widget/room_actions_sheet.dart';
import '../widget/room_connection_banner.dart';
import '../widget/room_scene.dart';
import '../widget/room_top_bar.dart';
import 'my_rooms_page_view.dart';
import 'report_sheet_view.dart';
import 'room_create_page_view.dart';
import 'room_discover_page_view.dart';
import 'room_edit_sheet_view.dart';
import 'room_members_sheet_view.dart';
import '../../../notification/provider/notification_providers.dart';
import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_provider.dart';

/// 房间主界面(#6b 定稿):全屏沉浸场景,无底部 nav。
/// 漂浮气泡(presence)+ 左右滑切换房间 + 底部扇形手牌(#5d 聚焦/上滑打出)
/// + 牌组切换(#4a)。悬浮层一律覆盖,不挤压布局。
class RoomMainView extends ConsumerStatefulWidget {
  const RoomMainView({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<RoomMainView> createState() => _RoomMainViewState();
}

class _RoomMainViewState extends ConsumerState<RoomMainView>
    with TickerProviderStateMixin {
  PageController? _pageController;
  Timer? _ticker;
  bool _fanFocused = false;
  int _fanCenterIndex = 0;
  bool _popoverOpen = false;
  bool _isPlaying = false;

  /// 今日面板(台子):展开程度、自己小人的上台 / 下台(add-home-sheet)。
  late final HomeStageController _stage = HomeStageController(
    vsync: this,
    expanded: AutoExpandPolicy.shouldExpand(
      trigger: AutoExpandTrigger.coldStart,
      layout: ref.read(homeSheetLayoutProvider),
      now: DateTime.now(),
    ),
    onLand: _onStageLand,
  );
  final _sheetKey = GlobalKey();

  /// 完成庆祝(design.md §5.5)。
  /// [_heldStatus]:升台途中继续显示的运动状态——落到台上才把「已完成」
  /// 交给小人,完成动作在台上播。
  UserActivityStatusEntity? _heldStatus;
  UserActivityStatusEntity? _lastActiveStatus;
  final ValueNotifier<int> _celebrations = ValueNotifier(0);
  Timer? _celebrationBeatTimer;
  Timer? _autoExpandTimer;
  List<String> _sheetModuleIds = const [];

  /// 没被看到的完成(完成时正在选卡 / 牌组下拉打开):退出后补播一次。
  int _pendingCelebrations = 0;
  DateTime? _pendingCelebrationAt;

  /// 上次离开 App 的时间(回到前台时判断是否自动展开)。
  DateTime? _leftAppAt;
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () => _leftAppAt = DateTime.now(),
    onResume: _onAppResumed,
  );

  bool get _overlayOpen => _fanFocused || _popoverOpen;

  void _onStageLand() {
    unawaited(HapticFeedback.lightImpact());
    if (_heldStatus != null && mounted) {
      // 落到台上:放开「已完成」,小人开始完成动作
      setState(() => _heldStatus = null);
      _scheduleCelebrationBeat();
    }
  }

  /// 起跳被打断(没落到台上)时也要放开,避免小人一直停在运动状态。
  void _onStageChanged() {
    if (_heldStatus != null && !_stage.isHopping && mounted) {
      setState(() => _heldStatus = null);
    }
  }

  /// 节拍与触感对齐完成动作的第一次落地。
  void _scheduleCelebrationBeat() {
    _celebrationBeatTimer?.cancel();
    _celebrationBeatTimer = Timer(
      CoFitMotion.avatarFinish * CoFitDecor.finishFirstLanding,
      () {
        if (!mounted) {
          return;
        }
        unawaited(HapticFeedback.mediumImpact());
        _celebrations.value++;
      },
    );
  }

  /// 自己做完一张卡。正在选卡 / 牌组下拉打开时不打断,记下来稍后补播。
  void _onOwnSessionCompleted() {
    final layout = ref.read(homeSheetLayoutProvider);
    if (!_stage.available ||
        !AutoExpandPolicy.shouldExpand(
          trigger: AutoExpandTrigger.completed,
          layout: layout,
          now: DateTime.now(),
        )) {
      return;
    }
    if (_overlayOpen) {
      _pendingCelebrations++;
      _pendingCelebrationAt = DateTime.now();
      return;
    }
    _playCelebration();
  }

  /// 播一次完成庆祝:台子升起接住小人,落到台上后小人做完成动作。
  /// 升台途中让小人继续显示最后的运动状态([_heldStatus]),落地时放开,
  /// 编排器由此进入完成动作;补播时同样如此(起手后接完成)。
  void _playCelebration() {
    if (_stage.onStage && !_stage.isHopping) {
      // 已在台上:完成动作原地播,只需要节拍
      _scheduleCelebrationBeat();
      return;
    }
    final hold = _lastActiveStatus;
    if (hold != null) {
      setState(() => _heldStatus = hold);
      _stage.expand(react: false);
    } else {
      _stage.expand();
      _scheduleCelebrationBeat();
    }
  }

  /// 退出选卡 / 关闭下拉后:有没被看到的完成且未过期 → 补播一次。
  void _replayPendingCelebration() {
    final count = _pendingCelebrations;
    final at = _pendingCelebrationAt;
    _pendingCelebrations = 0;
    _pendingCelebrationAt = null;
    if (!_stage.available ||
        !PendingCelebrationPolicy.shouldReplay(
          pendingCount: count,
          lastCompletedAt: at,
          now: DateTime.now(),
          layout: ref.read(homeSheetLayoutProvider),
        )) {
      return;
    }
    _playCelebration();
  }

  void _onAppResumed() {
    final leftAt = _leftAppAt;
    _leftAppAt = null;
    if (!mounted || !_stage.available || _stage.onStage || _overlayOpen) {
      return;
    }
    if (!AutoExpandPolicy.shouldExpand(
      trigger: AutoExpandTrigger.resumed,
      layout: ref.read(homeSheetLayoutProvider),
      now: DateTime.now(),
      leftAt: leftAt,
    )) {
      return;
    }
    // 稍等一下再展开,让用户看到面板是怎么来的
    _autoExpandTimer?.cancel();
    _autoExpandTimer = Timer(CoFitMotion.stageAutoExpandDelay, () {
      if (mounted && !_overlayOpen) {
        _stage.expand();
      }
    });
  }

  /// 面板实测高度(含底部安全区);首帧测量前为 0。
  double _sheetHeight = 0;

  /// 面板里要显示的模块:按布局配置取,去掉此刻没有内容的;
  /// debug 构建末尾加一个占位模块(带动画慢放开关)。没有模块时面板不出现。
  List<Widget> _sheetModules(List<ActionTemplateCard> fanCards) {
    final host = _SheetHost(this, fanCards);
    final specs = resolveHomeSheetModules(ref.watch(homeSheetLayoutProvider));
    _sheetModuleIds = [for (final spec in specs) spec.id];
    final visible = [
      for (final spec in specs)
        if (ref.watch(spec.status) != HomeSheetModuleStatus.empty) spec,
    ];
    if (visible.isEmpty) {
      return const [];
    }
    return [
      for (final spec in visible)
        KeyedSubtree(key: ValueKey(spec.id), child: spec.build(host)),
      if (kDebugMode) const HomeSheetDebugModule(),
    ];
  }

  /// 面板是否存在随模块变化;在帧结束后同步给台子(不能在 build 中通知)。
  void _syncStageAvailability(bool available) {
    if (_stage.available == available) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _stage.setAvailable(available);
      }
    });
  }

  /// 今日推荐等模块调用:手牌进入选卡状态并停在指定的卡上。
  bool _focusFanOnCard(String cardId, List<ActionTemplateCard> fanCards) {
    final index = fanCards.indexWhere((card) => card.id == cardId);
    setState(() {
      _fanFocused = true;
      _popoverOpen = false;
      if (index >= 0) {
        _fanCenterIndex = index;
      }
    });
    return index >= 0;
  }

  void _measureSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final height = _sheetKey.currentContext?.size?.height ?? 0;
      if (height != _sheetHeight) {
        setState(() => _sheetHeight = height);
      }
    });
  }

  /// 手牌区的元素随面板展开下沉并淡出;面板没完全收起前不响应点击。
  Widget _sinkWithStage(Widget child) {
    return AnimatedBuilder(
      animation: _stage,
      child: child,
      builder: (context, child) {
        final extent = _stage.extent;
        return IgnorePointer(
          ignoring: extent > 0,
          child: Opacity(
            opacity: (1 - extent / CoFitDecor.fanSinkFadeBy).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, CoFitDimens.sizeFanSink * extent),
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _toggleStage() {
    if (!_stage.available || _stage.isBusy) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    _stage.toggle();
  }

  @override
  void initState() {
    super.initState();
    // 会话剩余时间/到点回待机是随 now 的派生值(ActionSession 设计),
    // 有会话在进行时每秒重建一次以驱动倒计时与过期判定。
    _stage.addListener(_onStageChanged);
    _lifecycle; // 开始监听前后台切换
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final hasSessions = ref
          .read(roomBrowserProvider)
          .activityByRoom
          .values
          .any((snapshot) => !snapshot.isEmpty);
      if (hasSessions) {
        setState(() {});
      }
    });
  }

  /// presence 成员 + 事件流会话 合并:有会话者用会话状态覆盖,
  /// 否则保留 presence 自带快照(两条通道输出同一形状)。
  List<RoomPresenceMember> _mergedMembers(
    RoomBrowserState browser,
    String roomId,
    DateTime now,
  ) {
    final members = withSelfPresent(
      browser.presenceByRoom[roomId] ?? const <RoomPresenceMember>[],
      selfUserId: widget.userId,
      nickname: ref.read(ownNicknameProvider),
      activityStatus: ref.read(ownActivityStatusProvider),
    );
    final snapshot = browser.activityByRoom[roomId];
    if (snapshot == null || snapshot.isEmpty) {
      return members;
    }
    return [
      for (final member in members)
        switch (snapshot.activityStatusOf(member.userId, now)) {
          null => member,
          final status => member.copyWith(activityStatus: status),
        },
    ];
  }

  /// 在线成员 + Firestore 成员名单:离线成员以变暗占位留在场景里。
  /// 昵称:离线者无 presence,按 uid 读 profile(rules 对登录用户放开 read)。
  RoomRoster _roster(
    WidgetRef ref,
    String roomId,
    List<RoomPresenceMember> online,
  ) {
    final roomInfo = ref.watch(roomInfoProvider(roomId)).value;
    final rosterIds = roomMemberIdsOf(roomInfo, online);
    final onlineIds = {for (final m in online) m.userId};
    return withOfflineMembers(
      online,
      rosterIds: rosterIds,
      nicknames: {
        for (final uid in rosterIds)
          if (!onlineIds.contains(uid))
            uid: ref.watch(memberNicknameProvider(uid)).value,
      },
    );
  }

  /// 顶栏/内容给悬浮 dock 让出的左侧空间(与牌库页一致)。
  static const _dockInset =
      CoFitDimens.spacingLg +
      FloatingDock.collapsedWidth +
      CoFitDimens.spacingSm;

  void _closeOverlays() {
    setState(() {
      _fanFocused = false;
      _popoverOpen = false;
    });
    if (_pendingCelebrations > 0) {
      _replayPendingCelebration();
    }
  }

  Future<void> _switchDeck(ActionDeck deck) async {
    await ref.read(actionDeckRepositoryProvider).setActiveDeckId(deck.id);
    ref.invalidate(activeDeckIdProvider);
    if (mounted) {
      setState(() {
        _popoverOpen = false;
        _fanCenterIndex = 0;
      });
    }
  }

  Future<void> _openDeckSheet(List<ActionDeck> decks, String? activeId) async {
    setState(() => _popoverOpen = false);
    final selected = await showModalBottomSheet<ActionDeck>(
      context: context,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (context) => _DeckSheet(decks: decks, activeDeckId: activeId),
    );
    if (selected != null) {
      await _switchDeck(selected);
    }
  }

  Future<void> _playCard(ActionTemplateCard card, String roomId) async {
    if (_isPlaying) {
      return;
    }
    setState(() => _isPlaying = true);
    try {
      await ref
          .read(ownActionSessionProvider.notifier)
          .play(card: card, roomId: roomId, userId: widget.userId);
      if (!mounted) {
        return;
      }
      _closeOverlays();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已打出「${card.name}」,开始运动!')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('打出失败:$error')));
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  void _openBrowse() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyRoomsPageView(userId: widget.userId),
      ),
    );
  }

  Future<void> _openRoomActions({
    required String roomId,
    required String roomName,
    required bool isOwner,
  }) async {
    final action = await showModalBottomSheet<RoomSheetAction>(
      context: context,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (context) => RoomActionsSheet(
        roomName: roomName,
        isOwner: isOwner,
        isPushMuted: ref
            .read(notificationSettingsProvider)
            .value
            ?.isRoomMuted(roomId),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case RoomSheetAction.leave:
        await _confirmAndLeaveRoom(roomId: roomId, roomName: roomName);
      case RoomSheetAction.editInfo:
        final room = ref.read(roomInfoProvider(roomId)).value;
        if (room == null) {
          return;
        }
        await RoomEditSheetView.show(context, room: room);
      case RoomSheetAction.invite:
        await _shareInvite(roomId: roomId, roomName: roomName);
      case RoomSheetAction.members:
        await RoomMembersSheetView.show(
          context,
          roomId: roomId,
          viewerId: widget.userId,
        );
      case RoomSheetAction.toggleMute:
        await _togglePushMute(roomId: roomId, roomName: roomName);
      case RoomSheetAction.report:
        final submitted = await ReportSheetView.show(
          context,
          roomId: roomId,
          roomName: roomName,
          reporterId: widget.userId,
        );
        if (submitted == true && mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('已收到举报,感谢反馈')));
        }
      case RoomSheetAction.dissolve:
        await _confirmAndDissolveRoom(roomId: roomId, roomName: roomName);
    }
  }

  /// 静音 / 取消静音这个房间的伙伴推送(change add-partner-start-push)。
  Future<void> _togglePushMute({
    required String roomId,
    required String roomName,
  }) async {
    final muted =
        ref.read(notificationSettingsProvider).value?.isRoomMuted(roomId) ??
        false;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(setRoomPushMutedUsecaseProvider)
          .execute(userId: widget.userId, roomId: roomId, muted: !muted);
      unawaited(
        ref.read(analyticsTrackerProvider).log(AnalyticsEvents.roomPushMuted, {
          AnalyticsEvents.pMuted: AnalyticsEvents.flag(!muted),
        }),
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(muted ? '已恢复「$roomName」的通知' : '已静音「$roomName」的通知'),
          ),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('设置保存失败,请重试')));
    }
  }

  Future<void> _shareInvite({
    required String roomId,
    required String roomName,
  }) async {
    final room = ref.read(roomInfoProvider(roomId)).value;
    if (room == null) {
      return;
    }
    final link = ref.read(buildInviteLinkUsecaseProvider).execute(room: room);
    await SharePlus.instance.share(
      ShareParams(text: '来 CoFit 一起运动!加入我的房间「$roomName」:$link'),
    );
  }

  Future<void> _confirmAndDissolveRoom({
    required String roomId,
    required String roomName,
  }) async {
    final confirmed = await showDissolveRoomDialog(context, roomName: roomName);
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(dissolveRoomUsecaseProvider)
          .execute(roomId: roomId, ownerId: widget.userId);
      await ref.read(ablyRuntimeProvider.notifier).leaveRoom(roomId: roomId);
      await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已解散「$roomName」')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('解散失败:$error')));
    }
  }

  Future<void> _confirmAndLeaveRoom({
    required String roomId,
    required String roomName,
  }) async {
    final confirmed = await showCoFitConfirmSheet(
      context,
      title: '退出「$roomName」?',
      message: '退出后需要重新受邀或输入房间 ID 才能回来。',
      confirmLabel: '退出房间',
      danger: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      // 顺序:Firestore 退出 → Ably presence 退出 → 刷新已加入列表
      // (roomBrowserProvider 会随之取消该房间的订阅)。
      await ref
          .read(leaveRoomUsecaseProvider)
          .execute(roomId: roomId, userId: widget.userId);
      await ref.read(ablyRuntimeProvider.notifier).leaveRoom(roomId: roomId);
      await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已退出「$roomName」')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('退出失败:$error')));
    }
  }

  /// 被房主移出 / 房间被解散 的实时清理(每房间只跑一次)。
  /// roomInfoProvider 是 Firestore 快照流,变更秒级到达,不必等重启。
  final Set<String> _goneCleanupStarted = {};

  void _handleGoneRoom(String roomId, {required bool dissolved}) {
    if (!_goneCleanupStarted.add(roomId)) {
      return;
    }
    final name = ref.read(roomInfoProvider(roomId)).value?.name;
    final label = (name == null || name.isEmpty) ? '该房间' : '「$name」';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(dissolved ? '$label已解散' : '你已被移出$label')),
      );
    unawaited(cleanupRemovedRoom(ref, roomId: roomId, userId: widget.userId));
  }

  /// 对**所有**已加入房间做检测(不只当前聚焦的那间)。
  void _watchGoneRooms(List<String> joinedRoomIds) {
    for (final roomId in joinedRoomIds) {
      final info = ref.watch(roomInfoProvider(roomId));
      final dissolved = info.hasValue && info.value == null;
      final removed = wasRemovedFromRoom(info.value, widget.userId);
      if (dissolved || removed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleGoneRoom(roomId, dissolved: dissolved);
          }
        });
      }
    }
  }

  void _createFirstRoom() {
    RoomCreatePageView.push(context, userId: widget.userId);
  }

  void _discoverRooms() {
    RoomDiscoverPageView.push(context, userId: widget.userId);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _celebrationBeatTimer?.cancel();
    _autoExpandTimer?.cancel();
    _lifecycle.dispose();
    _pageController?.dispose();
    _stage.dispose();
    _celebrations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final browser = ref.watch(roomBrowserProvider);
    final joinedRoomIds = browser.joinedRoomIds;

    if (joinedRoomIds.isEmpty) {
      return _EmptyRooms(
        onCreate: _createFirstRoom,
        onDiscover: _discoverRooms,
        onBrowse: _openBrowse,
      );
    }

    final focusedRoomId = browser.focusedRoomId ?? joinedRoomIds.first;
    final roomIndex = (joinedRoomIds.indexOf(
      focusedRoomId,
    )).clamp(0, joinedRoomIds.length - 1);
    _pageController ??= PageController(initialPage: roomIndex);

    // 外部聚焦变更(邀请加入后跳转)→ PageView 跟随;
    // 用户自己滑动产生的变更被 currentPage 相等分支吸收。
    ref.listen<String?>(roomBrowserProvider.select((s) => s.focusedRoomId), (
      _,
      next,
    ) {
      final controller = _pageController;
      if (next == null || controller == null || !controller.hasClients) {
        return;
      }
      final targetIndex = ref
          .read(roomBrowserProvider)
          .joinedRoomIds
          .indexOf(next);
      if (targetIndex < 0 ||
          (controller.page?.round() ?? controller.initialPage) == targetIndex) {
        return;
      }
      controller.animateToPage(
        targetIndex,
        duration: CoFitMotion.fanTransition,
        curve: Curves.easeOut,
      );
    });

    final now = DateTime.now();
    final members = _mergedMembers(browser, focusedRoomId, now);
    final activeCount = members
        .where(
          (m) => m.activityStatus.activityState == UserActivityState.active,
        )
        .length;
    final roomInfo = ref.watch(roomInfoProvider(focusedRoomId)).value;
    final connection = ref.watch(roomConnectionStatusProvider(focusedRoomId));
    final hasBanner = connection != RoomConnectionStatus.live;
    _watchGoneRooms(joinedRoomIds);

    final decks = ref.watch(actionDecksProvider).value ?? const <ActionDeck>[];
    final activeDeck = ref.watch(activeDeckProvider);
    final fanCards = ref.watch(activeHandProvider);

    RoomPresenceMember? self;
    for (final member in members) {
      if (member.userId == widget.userId) {
        self = member;
        break;
      }
    }

    final safeTop = MediaQuery.paddingOf(context).top;
    // 底部 home indicator / 手势条:扇形手牌与牌组 chip 整体抬高,场景同步让位。
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final screenSize = MediaQuery.sizeOf(context);
    final sheetModules = _sheetModules(fanCards);
    _syncStageAvailability(sheetModules.isNotEmpty);
    final selfMember = self;
    // 自己小人显示的状态:升台途中(或计时已到、完成事件还没处理时)
    // 继续显示最后的运动状态,落到台上才切到「已完成」。
    final ownSession = ref.watch(ownActionSessionProvider);
    ref.listen(ownActionSessionProvider, (previous, next) {
      if (previous != null && next == null) {
        _onOwnSessionCompleted();
      }
    });
    final liveStatus = selfMember?.activityStatus;
    if (liveStatus != null &&
        liveStatus.activityState != UserActivityState.idle) {
      _lastActiveStatus = liveStatus;
    }
    final selfStatus =
        _heldStatus ??
        (ownSession != null &&
                liveStatus?.activityState == UserActivityState.idle &&
                _lastActiveStatus != null
            ? _lastActiveStatus
            : liveStatus);
    _stage.reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (sheetModules.isNotEmpty) {
      _measureSheet();
    }
    // 场景收起态的下边距(手牌区),展开时过渡到面板高度。
    final collapsedInset = safeBottom + CoFitDimens.sizeFanHeight;

    return Scaffold(
      body: Stack(
        children: [
          // 场景:左右滑切换房间
          Positioned.fill(
            child: GestureDetector(
              // 点房间里没有按钮的地方(含好友小人)= 收起今日面板
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_stage.onStage && !_stage.isBusy) {
                  _stage.collapse();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: joinedRoomIds.length,
                onPageChanged: (index) {
                  ref
                      .read(roomBrowserProvider.notifier)
                      .setFocusedRoom(joinedRoomIds[index]);
                },
                itemBuilder: (context, index) {
                  final roomId = joinedRoomIds[index];
                  return AnimatedBuilder(
                    animation: _stage,
                    builder: (context, child) => Padding(
                      padding: EdgeInsets.only(
                        top: safeTop + CoFitDimens.sizeMinTapTarget,
                        bottom: StageRules.sceneBottomInset(
                          collapsedInset: collapsedInset,
                          sheetHeight: _sheetHeight,
                          extent: _stage.extent,
                        ),
                      ),
                      child: child,
                    ),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final roster = _roster(
                          ref,
                          roomId,
                          _mergedMembers(browser, roomId, now),
                        );
                        return RoomScene(
                          members: roster.members,
                          offlineUserIds: roster.offlineUserIds,
                          selfUserId: widget.userId,
                          renderer: ref.watch(avatarRendererProvider),
                          // 自己的小人在独立一层(下方),不随房间滑动
                          showSelf: false,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // 自己的小人:独立一层,不随房间滑动;画在今日面板后面。
          // 面板高度测出来之前先不画台上的小人,避免首帧跳一下。
          if (selfMember != null && (_sheetHeight > 0 || !_stage.onStage))
            Positioned.fill(
              child: StageAvatarLayer(
                controller: _stage,
                floatRect: Rect.fromLTRB(
                  0,
                  safeTop + CoFitDimens.sizeMinTapTarget,
                  screenSize.width,
                  screenSize.height - collapsedInset,
                ),
                floatAnchor: RoomScene.selfAnchor,
                sheetHeight: _sheetHeight,
                feetY:
                    avatarViewboxHeight(CoFitDimens.sizeFigureSelf) *
                    avatarFeetFraction,
                onTap: _toggleStage,
                builder: (context) => AvatarBubble(
                  key: const ValueKey('self'),
                  name: '你',
                  state: selfStatus!.activityState,
                  actionType: RoomScene.actionTypeOf(
                    selfMember.copyWith(activityStatus: selfStatus),
                  ),
                  motionId: selfStatus.motionId,
                  chipText: RoomScene.chipTextOf(
                    selfMember.copyWith(activityStatus: selfStatus),
                  ),
                  isSelf: true,
                  renderer: ref.watch(avatarRendererProvider),
                  phaseSeed: RoomScene.phaseSeedOf(selfMember.userId),
                  grounded: _stage.onStage,
                  groundedReaction: _stage.reactToLastChange,
                  labelOpacity: _stage.labelOpacity,
                ),
              ),
            ),

          // 顶栏
          Positioned(
            top: safeTop + CoFitDimens.spacingSm,
            left: _dockInset,
            right: CoFitDimens.spacingLg,
            child: RoomTopBar(
              roomName: roomInfo?.name.isNotEmpty == true
                  ? roomInfo!.name
                  : focusedRoomId,
              memberCount: _roster(ref, focusedRoomId, members).members.length,
              activeCount: activeCount,
              roomIndex: roomIndex + 1,
              roomTotal: joinedRoomIds.length,
              onBrowseRooms: _openBrowse,
              onRoomActions: () => _openRoomActions(
                roomId: focusedRoomId,
                roomName: roomInfo?.name.isNotEmpty == true
                    ? roomInfo!.name
                    : focusedRoomId,
                isOwner: roomInfo?.ownerId == widget.userId,
              ),
            ),
          ),

          // 连接状态提示(live 时为空),悬浮在顶栏下方
          if (hasBanner)
            Positioned(
              top:
                  safeTop +
                  CoFitDimens.sizeMinTapTarget +
                  CoFitDimens.spacingXl,
              left: 0,
              right: 0,
              child: Center(child: RoomConnectionBanner(status: connection)),
            ),

          // HUD:自己运动中(有提示条时往下让一格)
          if (self != null &&
              self.activityStatus.activityState == UserActivityState.active)
            Positioned(
              top:
                  safeTop +
                  CoFitDimens.sizeMinTapTarget +
                  CoFitDimens.spacingXl +
                  (hasBanner ? CoFitDimens.sizeMinTapTarget : 0),
              left: 0,
              right: 0,
              child: Center(child: ActivityHud(status: self.activityStatus)),
            ),

          // 聚焦模式 scrim(盖住场景与顶栏,点击关闭)
          if (_fanFocused)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlays,
                child: ColoredBox(
                  color: colors.bgDeep.withValues(
                    alpha: CoFitOpacities.overlay,
                  ),
                ),
              ),
            ),

          // 聚焦模式顶部标题 + 牌组切换(#6b)
          if (_fanFocused)
            Positioned(
              top: safeTop + CoFitDimens.spacingXl,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text('选择下一项', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  DeckChip(
                    deckName: activeDeck?.name ?? '未选择牌组',
                    open: _popoverOpen,
                    onTap: () => setState(() => _popoverOpen = !_popoverOpen),
                  ),
                ],
              ),
            ),

          // 扇形手牌
          Positioned(
            left: 0,
            right: 0,
            bottom: safeBottom,
            child: _sinkWithStage(
              CardFan(
                cards: fanCards,
                focused: _fanFocused,
                centerIndex: _fanCenterIndex,
                onTapCollapsed: () => setState(() => _fanFocused = true),
                onFocusCard: (index) => setState(() => _fanCenterIndex = index),
                onPlay: (card) => unawaited(_playCard(card, focusedRoomId)),
              ),
            ),
          ),

          // 收起态牌组 chip(#6b 左下)
          if (!_fanFocused)
            Positioned(
              left: CoFitDimens.spacingXl,
              bottom: safeBottom + CoFitDimens.sizeDeckChipBottom,
              child: _sinkWithStage(
                DeckChip(
                  deckName: activeDeck?.name ?? '未选择牌组',
                  open: _popoverOpen,
                  onTap: () => setState(() => _popoverOpen = !_popoverOpen),
                ),
              ),
            ),

          // 今日面板(台子):展开时盖住收起态手牌,收起时完全移出屏幕
          if (sheetModules.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _stage,
                builder: (context, _) => FractionalTranslation(
                  translation: Offset(0, 1 - _stage.extent),
                  child: Transform.translate(
                    offset: Offset(0, _stage.dipOffset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            screenSize.height *
                            CoFitDecor.sheetMaxHeightFraction,
                      ),
                      child: HomeSheetPanel(
                        key: _sheetKey,
                        modules: sheetModules,
                        revealed: _stage.modulesRevealed,
                        bottomPadding: safeBottom,
                        reduceMotion: _stage.reduceMotion,
                        onHandleTap: _toggleStage,
                        onHandleDragStart: _stage.dragStart,
                        onHandleDragUpdate: (dy) {
                          if (_sheetHeight > 0) {
                            _stage.dragUpdate(-dy / _sheetHeight);
                          }
                        },
                        onHandleDragEnd: _stage.dragEnd,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 牌组下拉(悬浮,不挤压布局)
          if (_popoverOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _popoverOpen = false),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: _fanFocused ? 0 : CoFitDimens.spacingXl,
              right: _fanFocused ? 0 : null,
              top: _fanFocused
                  ? safeTop + CoFitDimens.sizeMinTapTarget * 2
                  : null,
              bottom: _fanFocused
                  ? null
                  : safeBottom +
                        CoFitDimens.sizeDeckChipBottom +
                        CoFitDimens.sizeDockItem +
                        CoFitDimens.spacingSm,
              child: Align(
                alignment: _fanFocused
                    ? Alignment.topCenter
                    : Alignment.bottomLeft,
                child: DeckPopover(
                  decks: decks,
                  activeDeckId: activeDeck?.id,
                  onSelect: (deck) => unawaited(_switchDeck(deck)),
                  onSeeAll: () =>
                      unawaited(_openDeckSheet(decks, activeDeck?.id)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 今日面板模块对房间页的窄接口实现。
class _SheetHost implements HomeSheetHost {
  const _SheetHost(this._state, this._fanCards);

  final _RoomMainViewState _state;
  final List<ActionTemplateCard> _fanCards;

  // 面板 / 小人的动画播完前不响应模块的操作(用户决议 2026-11-21)。
  @override
  void collapseSheet() {
    if (!_state._stage.isBusy) {
      _state._stage.collapse(react: false);
    }
  }

  @override
  bool focusFanOnCard(String cardId) {
    if (_state._stage.isBusy) {
      return false;
    }
    return _state._focusFanOnCard(cardId, _fanCards);
  }

  @override
  ValueListenable<int> get celebrations => _state._celebrations;

  @override
  Duration celebrationDelay(String moduleId) {
    final index = _state._sheetModuleIds.indexOf(moduleId);
    return CoFitMotion.celebrateBeatStagger * (index < 0 ? 0 : index);
  }
}

/// 房间 tab 空态(新用户首屏):主 CTA 直接建房,次 CTA 去「我的房间」手输 ID。
class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({
    required this.onCreate,
    required this.onDiscover,
    required this.onBrowse,
  });

  final VoidCallback onCreate;
  final VoidCallback onDiscover;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CoFitDimens.sizeAuthFormMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(CoFitDimens.spacing3xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: CoFitDimens.spacingLg,
                children: [
                  const IdleAvatarFigure(
                    figureHeight: CoFitDimens.sizeFigureHero,
                  ),
                  Column(
                    spacing: CoFitDimens.spacingXs,
                    children: [
                      Text(
                        '你的小人已就位',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: CoFitFontWeights.heading,
                        ),
                      ),
                      Text(
                        '建一间房把链接发给朋友,或者加入一间公开房间,一起打出第一张卡',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: CoFitDimens.spacingSm,
                    children: [
                      FilledButton(
                        onPressed: onCreate,
                        child: const Text('新建房间'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onDiscover,
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('发现公开房间'),
                      ),
                      TextButton(
                        onPressed: onBrowse,
                        child: Text(
                          '有邀请链接或房间 ID?',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// #4a「查看全部牌组」底部抽屉。
class _DeckSheet extends StatelessWidget {
  const _DeckSheet({required this.decks, required this.activeDeckId});

  final List<ActionDeck> decks;
  final String? activeDeckId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('选择牌组', style: textTheme.titleMedium),
            const SizedBox(height: CoFitDimens.spacingMd),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: decks.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: CoFitDimens.spacingSm),
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  final active = deck.id == activeDeckId;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(deck),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(CoFitDimens.spacingMd),
                      decoration: BoxDecoration(
                        color: active ? colors.primarySubtle : colors.bgDeep,
                        borderRadius: BorderRadius.circular(
                          CoFitDimens.radiusMd,
                        ),
                        border: Border.all(
                          color: active
                              ? colors.primaryBorder
                              : colors.borderSubtle,
                          width: CoFitDimens.borderWidthHairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              deck.name,
                              style: textTheme.labelLarge?.copyWith(
                                color: active
                                    ? colors.primaryMain
                                    : colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            active ? '使用中 ✓' : '${deck.cardIds.length} 张',
                            style: textTheme.labelSmall?.copyWith(
                              color: active
                                  ? colors.primaryMain
                                  : colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

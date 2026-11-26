import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/theme/cofit_dimens.dart';
import '../../../core/widget/cofit_confirm_sheet.dart';
import '../../invite/provider/pending_invite_provider.dart';
import '../../room/presentation/room_browser_provider.dart';
import '../../room/presentation/room_navigation.dart';
import '../../room/provider/room_info_provider.dart';
import '../domain/entity/push_message.dart';
import '../provider/notification_providers.dart';
import '../provider/push_offer_request_provider.dart';
import '../usecase/push_permission_prompt.dart';

/// 推送的生命周期接线,包在 AppShell 外层(已登录、启动数据就绪):
/// - 挂载 / 回到前台 / token 刷新时,让服务端的设备登记与系统权限一致;
/// - 点开伙伴开始运动的推送(冷启动或后台)→ 切到那个房间;
///   已不在那个房间就停在当前房间(spec: 点开推送进入房间);
/// - App 内通知提示:加入 / 新建房间后,或更新前就在有人的房间里时,先说明再弹系统请求。
class PushLifecycleBinder extends ConsumerStatefulWidget {
  const PushLifecycleBinder({
    required this.userId,
    required this.child,
    super.key,
  });

  final String userId;
  final Widget child;

  @override
  ConsumerState<PushLifecycleBinder> createState() =>
      _PushLifecycleBinderState();
}

class _PushLifecycleBinderState extends ConsumerState<PushLifecycleBinder>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<PushMessage>? _openedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final gateway = ref.read(pushMessagingGatewayProvider);
    _tokenSub = gateway.onTokenRefresh.listen(
      (token) => unawaited(_sync(token: token)),
      onError: (Object e) => debugPrint('push: token refresh error $e'),
    );
    _openedSub = gateway.openedMessages.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      unawaited(_sync());
      try {
        final initial = await gateway.initialMessage();
        if (initial != null && mounted) {
          _open(initial);
        }
      } catch (e) {
        debugPrint('push: initial message error $e');
      }
      unawaited(_offerForExistingMember());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(pushPermissionStatusProvider);
      unawaited(_sync());
    }
  }

  Future<void> _sync({String? token}) async {
    try {
      await ref
          .read(syncPushDeviceUsecaseProvider)
          .execute(userId: widget.userId, token: token);
    } catch (e) {
      // 离线 / 系统未就绪:下次回到前台再来。
      debugPrint('push: device sync failed $e');
    }
  }

  void _open(PushMessage message) {
    final roomId = message.partnerStartRoomId;
    if (roomId == null || !mounted) {
      return;
    }
    final joined = ref.read(roomBrowserProvider).joinedRoomIds;
    final entered = joined.contains(roomId);
    unawaited(
      ref.read(analyticsTrackerProvider).log(AnalyticsEvents.pushOpened, {
        AnalyticsEvents.pEntered: AnalyticsEvents.flag(entered),
      }),
    );
    if (!entered) {
      return;
    }
    unawaited(enterJoinedRoom(ref, Navigator.of(context), roomId: roomId));
  }

  // ── App 内通知提示(spec: 首次请求通知权限)──────────────────────────

  bool _offering = false;

  /// 更新前就在有其他成员的房间里、从没被问过的用户:打开 App 时问一次。
  /// 有滞留的邀请链接 / 刚加入的请求时让给它们(加入后会再触发)。
  Future<void> _offerForExistingMember() async {
    await Future<void>.delayed(CoFitMotion.pushOfferDelay);
    if (!mounted ||
        ref.read(pendingInviteProvider) != null ||
        ref.read(pushOfferRequestProvider) != null) {
      return;
    }
    try {
      if (!await ref.read(offerPushPermissionUsecaseProvider).canOffer()) {
        return;
      }
      if (!await _hasRoomWithOthers()) {
        return;
      }
    } catch (e) {
      debugPrint('push: offer check failed $e');
      return;
    }
    await _offer(roomName: null, trigger: AnalyticsEvents.triggerExisting);
  }

  Future<bool> _hasRoomWithOthers() async {
    for (final roomId in ref.read(roomBrowserProvider).joinedRoomIds) {
      final room = await ref.read(roomInfoProvider(roomId).future);
      final others = room?.memberIds.where((id) => id != widget.userId);
      if (others != null && others.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// 加入 / 新建流程成功后:等流程的界面收起、房间出现,再提示。
  Future<void> _offerAfterJoin(PushOfferRequest request) async {
    ref.read(pushOfferRequestProvider.notifier).clear();
    await Future<void>.delayed(CoFitMotion.pushOfferDelay);
    if (mounted) {
      final name = request.roomName.trim();
      await _offer(
        roomName: name.isEmpty ? null : name,
        isNewRoom: request.isNewRoom,
        trigger: request.isNewRoom
            ? AnalyticsEvents.triggerCreate
            : AnalyticsEvents.triggerJoin,
      );
    }
  }

  static String _offerMessage({
    required String? roomName,
    required bool isNewRoom,
  }) {
    final where = roomName == null ? '房间' : '「$roomName」';
    final what = isNewRoom
        ? '伙伴加入$where后开始运动,你会第一时间知道。'
        : '$where里有人开始运动,你会第一时间知道,一起动起来。';
    return '打开通知,$what不会刷屏,随时可以在「我的」里关闭。';
  }

  Future<void> _offer({
    required String? roomName,
    required String trigger,
    bool isNewRoom = false,
  }) async {
    if (_offering) {
      return;
    }
    _offering = true;
    final analytics = ref.read(analyticsTrackerProvider);
    try {
      final outcome = await ref
          .read(offerPushPermissionUsecaseProvider)
          .execute(
            userId: widget.userId,
            confirm: () async {
              if (!mounted) {
                return false;
              }
              unawaited(
                analytics.log(AnalyticsEvents.pushOfferShown, {
                  AnalyticsEvents.pTrigger: trigger,
                }),
              );
              final accepted = await showCoFitConfirmSheet(
                context,
                title: '伙伴开始运动时通知你?',
                message: _offerMessage(
                  roomName: roomName,
                  isNewRoom: isNewRoom,
                ),
                confirmLabel: '打开通知',
                cancelLabel: '以后再说',
                icon: Icons.notifications_active_outlined,
              );
              unawaited(
                analytics.log(AnalyticsEvents.pushOfferResult, {
                  AnalyticsEvents.pTrigger: trigger,
                  AnalyticsEvents.pAccepted: AnalyticsEvents.flag(
                    accepted == true,
                  ),
                }),
              );
              return accepted == true;
            },
          );
      if (outcome == PushOfferOutcome.requested) {
        final status = await ref
            .read(pushMessagingGatewayProvider)
            .permissionStatus();
        unawaited(
          analytics.log(AnalyticsEvents.pushPermissionResult, {
            AnalyticsEvents.pSource: AnalyticsEvents.sourceOffer,
            AnalyticsEvents.pResult: status.canReceive
                ? AnalyticsEvents.resultGranted
                : AnalyticsEvents.resultDenied,
          }),
        );
      }
      ref.invalidate(pushPermissionStatusProvider);
    } catch (e) {
      debugPrint('push: offer failed $e');
    } finally {
      _offering = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tokenSub?.cancel());
    unawaited(_openedSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PushOfferRequest?>(pushOfferRequestProvider, (_, request) {
      if (request != null) {
        unawaited(_offerAfterJoin(request));
      }
    });
    return widget.child;
  }
}

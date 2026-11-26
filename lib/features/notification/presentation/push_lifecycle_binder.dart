import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../room/presentation/room_browser_provider.dart';
import '../../room/presentation/room_navigation.dart';
import '../domain/entity/push_message.dart';
import '../provider/notification_providers.dart';

/// 推送的生命周期接线,包在 AppShell 外层(已登录、启动数据就绪):
/// - 挂载 / 回到前台 / token 刷新时,让服务端的设备登记与系统权限一致;
/// - 点开伙伴开始运动的推送(冷启动或后台)→ 切到那个房间;
///   已不在那个房间就停在当前房间(spec: 点开推送进入房间)。
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
    if (!joined.contains(roomId)) {
      return;
    }
    unawaited(enterJoinedRoom(ref, Navigator.of(context), roomId: roomId));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tokenSub?.cancel());
    unawaited(_openedSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

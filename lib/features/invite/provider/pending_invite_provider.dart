import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_links_deep_link_source.dart';
import '../domain/entity/invite_link_entity.dart';

final deepLinkSourceProvider = Provider<AppLinksDeepLinkSource>((ref) {
  return AppLinksDeepLinkSource();
});

/// 待处理的邀请链接(pending-link 模式):
/// 启动即订阅深链;登录前到达的链接滞留在此,
/// 由 InviteLinkGate(auth+onboarding 门内)消费并 clear。
class PendingInviteNotifier extends Notifier<InviteLinkEntity?> {
  StreamSubscription<InviteLinkEntity>? _subscription;

  @override
  InviteLinkEntity? build() {
    final source = ref.watch(deepLinkSourceProvider);
    unawaited(
      source.getInitialInvite().then((invite) {
        if (invite != null && state == null) {
          state = invite;
        }
      }),
    );
    _subscription?.cancel();
    _subscription = source.watchInvites().listen((invite) {
      state = invite;
    });
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return null;
  }

  void clear() {
    state = null;
  }
}

final pendingInviteProvider =
    NotifierProvider<PendingInviteNotifier, InviteLinkEntity?>(
  PendingInviteNotifier.new,
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cofit_colors.dart';
import '../../../core/theme/cofit_dimens.dart';
import '../domain/entity/invite_link_entity.dart';
import '../provider/pending_invite_provider.dart';
import 'view/invite_preview_sheet_view.dart';

/// 邀请深链消费点。包在 AppShell 外层(已过 auth+onboarding 门):
/// - 挂载时消费滞留的 pending 链接(登录前点开的情况);
/// - 运行中新链接到达时经 ref.listen 消费。
/// 消费 = clear provider + 弹邀请预览 sheet(防叠弹由 _isShowingSheet 保证)。
class InviteLinkGate extends ConsumerStatefulWidget {
  const InviteLinkGate({
    required this.userId,
    required this.child,
    super.key,
  });

  final String userId;
  final Widget child;

  @override
  ConsumerState<InviteLinkGate> createState() => _InviteLinkGateState();
}

class _InviteLinkGateState extends ConsumerState<InviteLinkGate> {
  bool _isShowingSheet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _consumePending();
      }
    });
  }

  void _consumePending() {
    final invite = ref.read(pendingInviteProvider);
    if (invite == null || _isShowingSheet) {
      return;
    }
    ref.read(pendingInviteProvider.notifier).clear();
    _showInviteSheet(invite);
  }

  Future<void> _showInviteSheet(InviteLinkEntity invite) async {
    _isShowingSheet = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CoFitDimens.radiusLg),
          ),
        ),
        builder: (context) => InvitePreviewSheetView(
          invite: invite,
          userId: widget.userId,
        ),
      );
    } finally {
      _isShowingSheet = false;
      if (mounted) {
        // sheet 关闭期间可能又来了新链接
        _consumePending();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InviteLinkEntity?>(pendingInviteProvider, (_, next) {
      if (next != null) {
        _consumePending();
      }
    });
    return widget.child;
  }
}

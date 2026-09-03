import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../auth/presentation/user_bootstrap_provider.dart';
import '../../../invite/domain/invite_link_format.dart';
import '../../domain/entity/room_info_entity.dart';
import '../create_room_provider.dart';
import '../room_browser_provider.dart';

/// 建房 sheet(stub 协议:无定稿设计,功能优先;替代旧 RoomCreatePage 整页)。
/// 表单(名称/可见性/描述)→ 成功态切换为分享卡片:
/// 主 CTA「分享邀请链接」+ 次 CTA 复制——创建和邀请是同一个动作。
class RoomCreateSheetView extends ConsumerStatefulWidget {
  const RoomCreateSheetView({required this.userId, super.key});

  final String userId;

  /// 统一入口:打开建房 sheet(每次打开先复位表单状态)。
  /// 返回 true = 用户点了「先进房间看看」(调用方据此收起自身,回房间主界面)。
  static Future<bool?> show(BuildContext context, {required String userId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => RoomCreateSheetView(userId: userId),
    );
  }

  @override
  ConsumerState<RoomCreateSheetView> createState() =>
      _RoomCreateSheetViewState();
}

class _RoomCreateSheetViewState extends ConsumerState<RoomCreateSheetView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createRoomProvider.notifier).reset();
      }
    });
  }

  Uri _inviteLink(String roomId, String hash) {
    return InviteLinkFormat.build(roomId: roomId, hash: hash);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    // 创建成功瞬间:拉取已加入列表(含 Ably 订阅)并聚焦新房间。
    // 刷新责任在 sheet 自己,不依赖调用方(修复:建房后列表不出现新房间)。
    ref.listen<CreateRoomState>(createRoomProvider, (previous, next) {
      final createdRoomId = next.createdRoomId;
      if (previous?.createdRoomId == null && createdRoomId != null) {
        unawaited(
          ref
              .read(userBootstrapProvider.notifier)
              .refreshJoinedRooms()
              .then((_) {
            ref.read(roomBrowserProvider.notifier).setFocusedRoom(createdRoomId);
          }),
        );
      }
    });

    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);
    final created =
        state.createdRoomId != null && state.createdShareLinkHash != null;

    return SafeArea(
      child: Padding(
        // 键盘弹起时表单上移
        padding: EdgeInsets.only(
          left: CoFitDimens.spacingXl,
          right: CoFitDimens.spacingXl,
          top: CoFitDimens.spacingXl,
          bottom:
              CoFitDimens.spacingXl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (created)
                _SuccessBody(
                  roomName: state.name,
                  link: _inviteLink(
                    state.createdRoomId!,
                    state.createdShareLinkHash!,
                  ),
                )
              else ...[
                Text(
                  '创建房间',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
                const SizedBox(height: CoFitDimens.spacingXl),
                _buildForm(state, notifier, colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    CreateRoomState state,
    CreateRoomNotifier notifier,
    CoFitColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          enabled: !state.isSubmitting,
          onChanged: notifier.updateName,
          decoration: const InputDecoration(
            labelText: '房间名(必填)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingMd),
        DropdownButtonFormField<String>(
          initialValue: state.visibility,
          items: RoomVisibility.allowed
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value == RoomVisibility.public ? '公开' : '仅邀请'),
                ),
              )
              .toList(growable: false),
          onChanged: state.isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    notifier.updateVisibility(value);
                  }
                },
          decoration: const InputDecoration(
            labelText: '可见性',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingMd),
        TextField(
          enabled: !state.isSubmitting,
          onChanged: notifier.updateDescription,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '描述',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        SizedBox(
          height: CoFitDimens.sizeMinTapTarget,
          child: FilledButton(
            onPressed: state.isSubmitting || state.name.trim().isEmpty
                ? null
                : () => notifier.submit(ownerId: widget.userId),
            child: state.isSubmitting
                ? SizedBox(
                    width: CoFitDimens.spacingLg,
                    height: CoFitDimens.spacingLg,
                    child: CircularProgressIndicator(
                      strokeWidth: CoFitDimens.borderWidthFocus,
                      color: colors.primaryOn,
                    ),
                  )
                : const Text('创建房间'),
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: CoFitDimens.spacingMd),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.statusDanger),
          ),
        ],
      ],
    );
  }
}

/// 建房成功态(#20b「创建即邀请」):✓ burst 徽章 + 「已就绪」+
/// 链接卡(等宽截断 + 复制小按钮)+ 主 CTA 分享 + 次级「先进房间看看」。
class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.roomName, required this.link});

  final String roomName;
  final Uri link;

  String get _shareText => '来 CoFit 一起运动!加入我的房间「$roomName」:$link';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _BurstBadge()),
        const SizedBox(height: CoFitDimens.spacingSm),
        Text(
          '「$roomName」已就绪',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: CoFitFontWeights.heading,
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingXs),
        Text(
          '把链接发给朋友,他们一键即可加入',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CoFitDimens.spacingMd,
            vertical: CoFitDimens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: colors.bgDeep,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
            border: Border.all(
              color: colors.borderStrong,
              width: CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Row(
            spacing: CoFitDimens.spacingSm,
            children: [
              Icon(
                Icons.link_rounded,
                size: CoFitDimens.sizeCardIcon,
                color: colors.primaryMain,
              ),
              Expanded(
                child: Text(
                  '$link',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '$link'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          const SnackBar(content: Text('已复制')));
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CoFitDimens.spacingSm,
                    vertical: CoFitDimens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(CoFitDimens.radiusSm),
                    border: Border.all(
                      color: colors.borderStrong,
                      width: CoFitDimens.borderWidthHairline,
                    ),
                  ),
                  child: Text(
                    '复制',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: CoFitFontWeights.heading,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        SizedBox(
          height: CoFitDimens.sizeMinTapTarget,
          child: FilledButton.icon(
            onPressed: () {
              SharePlus.instance.share(ShareParams(text: _shareText));
            },
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('分享给朋友'),
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingXs),
        SizedBox(
          height: CoFitDimens.sizeMinTapTarget,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '先进房间看看',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
        ),
      ],
    );
  }
}

/// ✓ 圆徽 + 外扩光圈动画(#20b,burstRing 周期 token)。
class _BurstBadge extends StatefulWidget {
  const _BurstBadge();

  @override
  State<_BurstBadge> createState() => _BurstBadgeState();
}

class _BurstBadgeState extends State<_BurstBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CoFitMotion.burstRing,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return SizedBox(
      width: CoFitDimens.sizeSuccessBadge,
      height: CoFitDimens.sizeSuccessBadge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: CoFitDecor.fanFocusScale)
                .animate(CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(
              opacity: Tween<double>(begin: CoFitOpacities.border, end: 0)
                  .animate(_controller),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primaryMain,
                    width: CoFitDimens.borderWidthFocus,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: CoFitDimens.sizeSuccessBadge,
            height: CoFitDimens.sizeSuccessBadge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primarySubtle,
              border: Border.all(
                color: colors.primaryBorder,
                width: CoFitDimens.borderWidthHairline,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              color: colors.primaryMain,
              size: CoFitDimens.sizeCheckBadge,
            ),
          ),
        ],
      ),
    );
  }
}

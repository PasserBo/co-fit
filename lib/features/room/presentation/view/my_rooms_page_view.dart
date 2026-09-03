import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../auth/presentation/user_bootstrap_provider.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';
import '../../domain/entity/room_presence_member.dart';
import '../../domain/entity/user_activity_status_entity.dart';
import '../../provider/room_info_provider.dart';
import '../join_room_provider.dart';
import '../room_browser_provider.dart';
import 'room_create_sheet_view.dart';

/// 「我的房间」(#20c 定稿,替代旧 RoomBrowsePage/RoomCommunityPage):
/// 已加入房间列表(presence 副行 + 当前/进入)+ ＋新建 +
/// 页尾「手动输入房间 ID」次要入口 + 空态双 CTA。
class MyRoomsPageView extends ConsumerWidget {
  const MyRoomsPageView({required this.userId, super.key});

  final String userId;

  Future<void> _manualJoin(BuildContext context, WidgetRef ref) async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => _ManualJoinSheet(userId: userId),
    );
    if (joined == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已加入房间')));
    }
  }

  void _enterRoom(BuildContext context, WidgetRef ref, String roomId) {
    ref.read(roomBrowserProvider.notifier).setFocusedRoom(roomId);
    Navigator.of(context).pop();
  }

  Future<void> _handleDissolvedRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('该房间已解散')));
    // 懒清理:移除残留 membership(leaveRoom 容忍房间不存在)。
    try {
      await ref
          .read(leaveRoomUsecaseProvider)
          .execute(roomId: roomId, userId: userId);
      await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
    } catch (_) {
      // 清理失败不打扰用户,下次进入再试。
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final browser = ref.watch(roomBrowserProvider);
    final joinedRoomIds = browser.joinedRoomIds;
    final focusedRoomId = browser.focusedRoomId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的房间'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: CoFitDimens.spacingLg),
            child: FilledButton.icon(
              onPressed: () =>
                  RoomCreateSheetView.show(context, userId: userId),
              icon: const Icon(Icons.add, size: CoFitDimens.sizeCardIcon),
              label: const Text('新建'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: joinedRoomIds.isEmpty
            ? _EmptyRooms(
                onCreate: () =>
                    RoomCreateSheetView.show(context, userId: userId),
                onManualJoin: () => _manualJoin(context, ref),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        CoFitDimens.spacingLg,
                        CoFitDimens.spacingXs,
                        CoFitDimens.spacingLg,
                        CoFitDimens.spacingSm,
                      ),
                      itemCount: joinedRoomIds.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CoFitDimens.spacingSm),
                      itemBuilder: (context, index) {
                        final roomId = joinedRoomIds[index];
                        return _RoomRow(
                          roomId: roomId,
                          userId: userId,
                          isCurrent: roomId == focusedRoomId,
                          members: ref.watch(roomPresenceByIdProvider(roomId)),
                          onEnter: () => _enterRoom(context, ref, roomId),
                          onDissolved: () =>
                              _handleDissolvedRoom(context, ref, roomId),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(CoFitDimens.spacingSm),
                    child: TextButton(
                      onPressed: () => _manualJoin(context, ref),
                      child: Text.rich(
                        TextSpan(
                          text: '有房间 ID? ',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textDisabled,
                          ),
                          children: [
                            TextSpan(
                              text: '手动输入加入',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: CoFitFontWeights.label,
                                decoration: TextDecoration.underline,
                                decorationColor: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoomRow extends ConsumerWidget {
  const _RoomRow({
    required this.roomId,
    required this.userId,
    required this.isCurrent,
    required this.members,
    required this.onEnter,
    required this.onDissolved,
  });

  final String roomId;
  final String userId;
  final bool isCurrent;
  final List<RoomPresenceMember> members;
  final VoidCallback onEnter;
  final VoidCallback onDissolved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final roomInfoAsync = ref.watch(roomInfoProvider(roomId));
    final roomInfo = roomInfoAsync.value;
    final isDissolved = roomInfoAsync.hasValue && roomInfo == null;
    final isOwner = roomInfo?.ownerId == userId;

    final activeCount = members
        .where((m) =>
            m.activityStatus.activityState == UserActivityState.active)
        .length;

    return GestureDetector(
      onTap: isDissolved ? onDissolved : onEnter,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(CoFitDimens.spacingMd),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
          border: Border.all(
            color: isCurrent ? colors.primaryBorder : colors.borderSubtle,
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
        child: Row(
          spacing: CoFitDimens.spacingMd,
          children: [
            IdleAvatarFigure(
              figureHeight: CoFitDimens.sizeDeckStackHeight,
              withHeadRing: isCurrent,
              dimmed: !isCurrent,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isDissolved
                              ? '房间已解散'
                              : (roomInfo?.name.isNotEmpty == true
                                  ? roomInfo!.name
                                  : roomId),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: CoFitFontWeights.heading,
                            color: isDissolved
                                ? colors.textTertiary
                                : colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: CoFitDimens.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CoFitDimens.spacingXs,
                            vertical: CoFitDimens.spacingXs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.typeCoreSubtle,
                            borderRadius: BorderRadius.circular(
                              CoFitDimens.radiusSm,
                            ),
                            border: Border.all(
                              color: colors.statusPaused.withValues(
                                alpha: CoFitOpacities.border,
                              ),
                              width: CoFitDimens.borderWidthHairline,
                            ),
                          ),
                          child: Text(
                            '房主',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.statusPaused,
                              fontWeight: CoFitFontWeights.label,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: CoFitDimens.spacingXs / 2),
                  if (isDissolved)
                    Text(
                      '点按移除',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textDisabled,
                      ),
                    )
                  else
                    Row(
                      spacing: CoFitDimens.spacingXs,
                      children: [
                        if (activeCount > 0)
                          _ShimmerDot(color: colors.statusActive),
                        Flexible(
                          child: Text(
                            activeCount > 0
                                ? '$activeCount 人正在运动 · ${members.length} 人在线'
                                : (members.isEmpty
                                    ? '暂无人在线'
                                    : '暂无人运动 · ${members.length} 人在线'),
                            style: textTheme.labelSmall?.copyWith(
                              color: activeCount > 0
                                  ? colors.primaryMain
                                  : colors.textTertiary,
                              fontWeight: activeCount > 0
                                  ? CoFitFontWeights.label
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!isDissolved)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoFitDimens.spacingMd,
                  vertical: CoFitDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
                  border: Border.all(
                    color: isCurrent
                        ? colors.primaryBorder
                        : colors.borderStrong,
                    width: CoFitDimens.borderWidthHairline,
                  ),
                ),
                child: Text(
                  isCurrent ? '当前' : '进入',
                  style: textTheme.labelSmall?.copyWith(
                    color: isCurrent
                        ? colors.primaryMain
                        : colors.textSecondary,
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// presence 呼吸绿点(#20c,shimmer 周期 token)。
class _ShimmerDot extends StatefulWidget {
  const _ShimmerDot({required this.color});

  final Color color;

  @override
  State<_ShimmerDot> createState() => _ShimmerDotState();
}

class _ShimmerDotState extends State<_ShimmerDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CoFitMotion.shimmer,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: CoFitOpacities.border, end: 1)
          .animate(_controller),
      child: Container(
        width: CoFitDimens.sizeRoomDot,
        height: CoFitDimens.sizeRoomDot,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onCreate, required this.onManualJoin});

  final VoidCallback onCreate;
  final VoidCallback onManualJoin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacing3xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoFitDimens.spacingLg,
          children: [
            const IdleAvatarFigure(
                figureHeight: CoFitDimens.sizeFigureHero),
            Column(
              spacing: CoFitDimens.spacingXs,
              children: [
                Text(
                  '还没有加入任何房间',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
                Text(
                  '新建一间,或点开朋友发来的邀请链接',
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
                TextButton(
                  onPressed: onManualJoin,
                  child: Text(
                    '手动输入房间 ID 加入',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualJoinSheet extends ConsumerStatefulWidget {
  const _ManualJoinSheet({required this.userId});

  final String userId;

  @override
  ConsumerState<_ManualJoinSheet> createState() => _ManualJoinSheetState();
}

class _ManualJoinSheetState extends ConsumerState<_ManualJoinSheet> {
  final _controller = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final roomId = _controller.text.trim();
    if (roomId.isEmpty) {
      setState(() => _errorMessage = '请输入房间 ID');
      return;
    }
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(joinRoomUsecaseProvider)
          .execute(roomId: roomId, userId: widget.userId);
      await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = '加入失败:$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: CoFitDimens.spacingXl,
          right: CoFitDimens.spacingXl,
          top: CoFitDimens.spacingXl,
          bottom:
              CoFitDimens.spacingXl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '输入房间 ID 加入',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            TextField(
              controller: _controller,
              enabled: !_isJoining,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '房间 ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            SizedBox(
              height: CoFitDimens.sizeMinTapTarget,
              child: FilledButton(
                onPressed: _isJoining ? null : _join,
                child: _isJoining
                    ? SizedBox(
                        width: CoFitDimens.spacingLg,
                        height: CoFitDimens.spacingLg,
                        child: CircularProgressIndicator(
                          strokeWidth: CoFitDimens.borderWidthFocus,
                          color: colors.primaryOn,
                        ),
                      )
                    : const Text('加入'),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: CoFitDimens.spacingMd),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.statusDanger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

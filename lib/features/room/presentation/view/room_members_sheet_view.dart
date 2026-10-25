import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/cofit_confirm_sheet.dart';
import '../../../../firestore/ably_state_machine.dart';
import '../../../auth/presentation/user_bootstrap_provider.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';
import '../../domain/entity/room_info_entity.dart';
import '../../domain/entity/room_presence_member.dart';
import '../../provider/member_nickname_provider.dart';
import '../../provider/room_info_provider.dart';
import '../join_room_provider.dart';
import '../room_browser_provider.dart';
import '../widget/room_scene.dart';

/// 成员管理 sheet(stub 协议:无定稿设计,功能优先;UGC 合规必需)。
/// 成员列表 = Firestore `members`(memberIds)∪ presence 在线成员;
/// 房主可「移出」非房主成员(二次确认);被移出者靠懒清理感知。
class RoomMembersSheetView extends ConsumerStatefulWidget {
  const RoomMembersSheetView({
    required this.roomId,
    required this.viewerId,
    super.key,
  });

  final String roomId;
  final String viewerId;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required String viewerId,
  }) {
    // 不开 isScrollControlled:由 Flutter 默认把 sheet 高度封顶,列表内滚动。
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => RoomMembersSheetView(roomId: roomId, viewerId: viewerId),
    );
  }

  @override
  ConsumerState<RoomMembersSheetView> createState() =>
      _RoomMembersSheetViewState();
}

class _RoomMembersSheetViewState extends ConsumerState<RoomMembersSheetView> {
  String get roomId => widget.roomId;
  String get viewerId => widget.viewerId;

  /// 操作反馈走 sheet 内联(SnackBar 会被本 sheet 挡住)。
  String? _errorMessage;
  String? _removingUserId;

  Future<void> _confirmAndRemove({
    required String memberUserId,
    required String displayName,
  }) async {
    final confirmed = await showCoFitConfirmSheet(
      context,
      title: '移出「$displayName」?',
      message: '对方将离开本房间;持有邀请链接或房间 ID 仍可重新加入。',
      confirmLabel: '移出',
      danger: true,
      icon: Icons.person_remove_outlined,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _errorMessage = null;
      _removingUserId = memberUserId;
    });
    try {
      await ref
          .read(removeRoomMemberUsecaseProvider)
          .execute(
            roomId: roomId,
            ownerId: viewerId,
            memberUserId: memberUserId,
          );
      // 成功反馈 = 列表实时少一行(roomInfoProvider 为快照流),无需 toast。
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = '移出「$displayName」失败:$error');
      }
    } finally {
      if (mounted) {
        setState(() => _removingUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final roomInfoAsync = ref.watch(roomInfoProvider(roomId));
    final roomInfo = roomInfoAsync.value;
    final presence = ref.watch(roomPresenceByIdProvider(roomId));
    final presenceByUid = {for (final m in presence) m.userId: m};
    final isViewerOwner = roomInfo?.ownerId == viewerId;

    final ids = roomMemberIdsOf(roomInfo, presence);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '成员',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingXs),
            Text(
              '${ids.length} 名成员 · ${presence.length} 人在线',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            if (roomInfoAsync.isLoading && roomInfo == null)
              const Padding(
                padding: EdgeInsets.all(CoFitDimens.spacingXl),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ids.length,
                  separatorBuilder: (_, _) => Divider(
                    height: CoFitDimens.borderWidthHairline,
                    color: colors.borderSubtle,
                  ),
                  itemBuilder: (context, index) {
                    final uid = ids[index];
                    final presenceMember = presenceByUid[uid];
                    return _MemberRow(
                      uid: uid,
                      isSelf: uid == viewerId,
                      isOwner: uid == roomInfo?.ownerId,
                      presenceMember: presenceMember,
                      canRemove:
                          isViewerOwner &&
                          uid != viewerId &&
                          uid != roomInfo?.ownerId,
                      isRemoving: _removingUserId == uid,
                      onRemove: (name) => _confirmAndRemove(
                        memberUserId: uid,
                        displayName: name,
                      ),
                    );
                  },
                ),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: CoFitDimens.spacingSm),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.statusDanger,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.uid,
    required this.isSelf,
    required this.isOwner,
    required this.presenceMember,
    required this.canRemove,
    required this.isRemoving,
    required this.onRemove,
  });

  final String uid;
  final bool isSelf;
  final bool isOwner;
  final RoomPresenceMember? presenceMember;
  final bool canRemove;
  final bool isRemoving;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final online = presenceMember != null;

    // 昵称优先级:presence 下发 → users/{uid} profile → uid 截断
    final presenceName = presenceMember?.nickname?.trim();
    final profileName = (presenceName == null || presenceName.isEmpty)
        ? ref.watch(memberNicknameProvider(uid)).value
        : null;
    final name = (presenceName != null && presenceName.isNotEmpty)
        ? presenceName
        : (profileName ??
              RoomScene.displayName(
                RoomPresenceMember(clientId: uid, userId: uid),
              ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoFitDimens.spacingSm),
      child: Row(
        spacing: CoFitDimens.spacingMd,
        children: [
          IdleAvatarFigure(
            figureHeight: CoFitDimens.sizeDeckStackHeight,
            withHeadRing: online,
            dimmed: !online,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: CoFitDimens.spacingSm,
                  children: [
                    Flexible(
                      child: Text(
                        isSelf ? '$name(我)' : name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: CoFitFontWeights.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwner) _OwnerBadge(),
                  ],
                ),
                Row(
                  spacing: CoFitDimens.spacingXs,
                  children: [
                    Container(
                      width: CoFitDimens.sizeRoomDot,
                      height: CoFitDimens.sizeRoomDot,
                      decoration: BoxDecoration(
                        color: online ? colors.statusActive : colors.statusIdle,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      online ? '在线' : '离线',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canRemove)
            SizedBox(
              height: CoFitDimens.sizeMinTapTarget,
              child: TextButton(
                onPressed: isRemoving ? null : () => onRemove(name),
                child: isRemoving
                    ? SizedBox(
                        width: CoFitDimens.sizeCardIcon,
                        height: CoFitDimens.sizeCardIcon,
                        child: CircularProgressIndicator(
                          strokeWidth: CoFitDimens.borderWidthFocus,
                          color: colors.statusDanger,
                        ),
                      )
                    : Text(
                        '移出',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.statusDanger,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingXs,
        vertical: CoFitDimens.spacingXs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.typeCoreSubtle,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
        border: Border.all(
          color: colors.statusPaused.withValues(alpha: CoFitOpacities.border),
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Text(
        '房主',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.statusPaused,
          fontWeight: CoFitFontWeights.label,
        ),
      ),
    );
  }
}

/// 房间成员(含离线)的 uid 列表,有序:房主 → memberIds 顺序 → 仅在 presence 里的。
List<String> roomMemberIdsOf(
  RoomInfoEntity? roomInfo,
  List<RoomPresenceMember> presence,
) {
  final ids = <String>[];
  if (roomInfo != null) {
    ids.add(roomInfo.ownerId);
    for (final id in roomInfo.memberIds) {
      if (!ids.contains(id)) {
        ids.add(id);
      }
    }
  }
  for (final m in presence) {
    if (!ids.contains(m.userId)) {
      ids.add(m.userId);
    }
  }
  return ids;
}

/// 清理入口:当前用户已不在房间成员列表(被房主移出)时为 true。
/// 缓存快照一律不算(可能是加入前缓存的旧文档,会把自己误踢出去)。
bool wasRemovedFromRoom(RoomInfoEntity? roomInfo, String userId) {
  return roomInfo != null && !roomInfo.fromCache && !roomInfo.isMember(userId);
}

/// 被移出后的本地清理:删残留 membership → Ably 离场 → 刷新已加入列表。
Future<void> cleanupRemovedRoom(
  WidgetRef ref, {
  required String roomId,
  required String userId,
}) async {
  try {
    await ref
        .read(leaveRoomUsecaseProvider)
        .execute(roomId: roomId, userId: userId);
  } catch (_) {
    // 清理失败不打扰用户,下次进入再试。
  }
  try {
    await ref.read(ablyRuntimeProvider.notifier).leaveRoom(roomId: roomId);
    await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
  } catch (_) {
    // 同上。
  }
}

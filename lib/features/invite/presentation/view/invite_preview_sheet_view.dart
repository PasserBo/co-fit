import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_shell_index_provider.dart';
import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../auth/presentation/user_bootstrap_provider.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';
import '../../../room/presentation/join_room_provider.dart';
import '../../../room/presentation/room_browser_provider.dart';
import '../../domain/entity/invite_link_entity.dart';
import '../../provider/invite_usecase_providers.dart';
import '../../usecase/resolve_invite_usecase.dart';

/// 邀请预览 sheet(stub 协议:无定稿设计,功能优先)。
/// 打开即解析链接:无效 → 错误态;有效 → 房间信息 + 加入 CTA。
/// 加入成功后:刷新已加入列表 → 聚焦该房间 → 切回房间 tab。
class InvitePreviewSheetView extends ConsumerStatefulWidget {
  const InvitePreviewSheetView({
    required this.invite,
    required this.userId,
    super.key,
  });

  final InviteLinkEntity invite;
  final String userId;

  @override
  ConsumerState<InvitePreviewSheetView> createState() =>
      _InvitePreviewSheetViewState();
}

class _InvitePreviewSheetViewState
    extends ConsumerState<InvitePreviewSheetView> {
  ResolveInviteResult? _result;
  String? _errorMessage;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final joinedRoomIds = ref.read(userBootstrapProvider).joinedRoomIds;
      final result = await ref.read(resolveInviteUsecaseProvider).execute(
            link: widget.invite,
            joinedRoomIds: joinedRoomIds,
          );
      if (mounted) {
        setState(() => _result = result);
      }
    } on InviteInvalidException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.reason);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '邀请解析失败,请检查网络后重试。');
      }
    }
  }

  Future<void> _join(ResolveInviteResult result) async {
    if (_isJoining) {
      return;
    }
    setState(() => _isJoining = true);
    try {
      if (!result.alreadyJoined) {
        await ref.read(joinRoomUsecaseProvider).execute(
              roomId: result.room.roomId,
              userId: widget.userId,
            );
        await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
      }
      ref
          .read(roomBrowserProvider.notifier)
          .setFocusedRoom(result.room.roomId);
      ref.read(appShellIndexProvider.notifier).set(0);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
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
    final textTheme = Theme.of(context).textTheme;
    final result = _result;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '收到房间邀请',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: colors.primaryMain,
                fontWeight: CoFitFontWeights.heading,
                letterSpacing: CoFitTypography.letterSpacingWide,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            if (_errorMessage != null) ...[
              // 链接失效:卡片区换失效说明 + 「知道了」(#20a)
              Container(
                padding: const EdgeInsets.all(CoFitDimens.spacingXl),
                decoration: BoxDecoration(
                  color: colors.bgDeep,
                  borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
                  border: Border.all(
                    color: colors.borderStrong,
                    width: CoFitDimens.borderWidthHairline,
                  ),
                ),
                child: Column(
                  spacing: CoFitDimens.spacingSm,
                  children: [
                    Icon(
                      Icons.link_off_rounded,
                      size: CoFitDimens.sizeBannerIcon,
                      color: colors.statusDanger,
                    ),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingLg),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('知道了'),
                ),
              ),
            ] else if (result == null)
              const Padding(
                padding: EdgeInsets.all(CoFitDimens.spacing2xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _RoomInviteCard(
                name: result.room.name,
                description: result.room.description,
              ),
              const SizedBox(height: CoFitDimens.spacingLg),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: FilledButton(
                  onPressed: _isJoining ? null : () => _join(result),
                  child: _isJoining
                      ? SizedBox(
                          width: CoFitDimens.spacingLg,
                          height: CoFitDimens.spacingLg,
                          child: CircularProgressIndicator(
                            strokeWidth: CoFitDimens.borderWidthFocus,
                            color: colors.primaryOn,
                          ),
                        )
                      : Text(result.alreadyJoined ? '进入房间' : '加入房间'),
                ),
              ),
            ],
            if (_errorMessage == null) ...[
              const SizedBox(height: CoFitDimens.spacingSm),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: TextButton(
                  onPressed:
                      _isJoining ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    '暂不',
                    style: TextStyle(color: colors.textTertiary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 房间邀请卡(#20a):上半 = 剪影氛围区(中央发光小人 + 两侧灰剪影,
/// 静态装饰,不依赖成员数据 —— 传达「有人等你」但不谎报人数);
/// 下半 = 房名 + 描述(空描述整块收起,卡片只剩房名行)。
class _RoomInviteCard extends StatelessWidget {
  const _RoomInviteCard({required this.name, required this.description});

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgDeep,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.borderStrong,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: CoFitDimens.sizeInviteBand,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.6),
                  radius: 1,
                  colors: [
                    colors.primaryMain
                        .withValues(alpha: CoFitOpacities.subtle),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Align(
                    alignment: const Alignment(-0.55, 1),
                    child: Opacity(
                      opacity: CoFitOpacities.silhouetteFar,
                      child: const IdleAvatarFigure(
                        figureHeight: CoFitDimens.sizeFigureFriend,
                        withHeadRing: false,
                        dimmed: true,
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.55, 0.9),
                    child: Opacity(
                      opacity: CoFitOpacities.silhouetteNear,
                      child: const IdleAvatarFigure(
                        figureHeight: CoFitDimens.sizeFigureFriend,
                        withHeadRing: false,
                        dimmed: true,
                      ),
                    ),
                  ),
                  const IdleAvatarFigure(
                    figureHeight: CoFitDimens.sizeFigureSelf,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(CoFitDimens.spacingMd),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.borderSubtle,
                  width: CoFitDimens.borderWidthHairline,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: CoFitDimens.spacingXs),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

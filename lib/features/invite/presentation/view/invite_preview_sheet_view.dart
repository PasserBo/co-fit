import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_shell_index_provider.dart';
import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../auth/presentation/user_bootstrap_provider.dart';
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
              '房间邀请',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            if (_errorMessage != null) ...[
              Icon(
                Icons.link_off_rounded,
                size: CoFitDimens.sizeBannerIcon,
                color: colors.statusDanger,
              ),
              const SizedBox(height: CoFitDimens.spacingMd),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.statusDanger),
              ),
            ] else if (result == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                result.room.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: CoFitFontWeights.heading,
                ),
              ),
              if (result.room.description.isNotEmpty) ...[
                const SizedBox(height: CoFitDimens.spacingSm),
                Text(
                  result.room.description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: CoFitDimens.spacingXl),
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
        ),
      ),
    );
  }
}

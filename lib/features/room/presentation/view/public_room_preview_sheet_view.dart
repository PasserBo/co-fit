import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/room_info_entity.dart';
import '../join_room_provider.dart';

/// 公开房间预览(沿用 #20a 邀请预览的文字语言):房名 / 简介 / 成员数 +「加入」。
/// 加入成功 pop(true),由调用方负责进房导航;失败内联显示,可重试或关闭。
class PublicRoomPreviewSheetView extends ConsumerStatefulWidget {
  const PublicRoomPreviewSheetView({
    required this.room,
    required this.userId,
    super.key,
  });

  final RoomInfoEntity room;
  final String userId;

  static Future<bool?> show(
    BuildContext context, {
    required RoomInfoEntity room,
    required String userId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => PublicRoomPreviewSheetView(room: room, userId: userId),
    );
  }

  @override
  ConsumerState<PublicRoomPreviewSheetView> createState() =>
      _PublicRoomPreviewSheetViewState();
}

class _PublicRoomPreviewSheetViewState
    extends ConsumerState<PublicRoomPreviewSheetView> {
  bool _isJoining = false;
  String? _errorMessage;

  Future<void> _join() async {
    if (_isJoining) {
      return;
    }
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(joinRoomUsecaseProvider)
          .execute(roomId: widget.room.roomId, userId: widget.userId);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = '加入失败,请检查网络后重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final room = widget.room;
    final description = room.description.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingXl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '公开房间',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.primaryMain,
                  fontWeight: CoFitFontWeights.label,
                  letterSpacing: CoFitTypography.letterSpacingWide,
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingSm),
              Text(
                room.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: CoFitFontWeights.heading,
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingXs),
              Text(
                '${room.memberIds.length} 名成员',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: CoFitDimens.spacingLg),
                Container(
                  padding: const EdgeInsets.all(CoFitDimens.spacingMd),
                  decoration: BoxDecoration(
                    color: colors.bgDeep,
                    borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
                    border: Border.all(
                      color: colors.borderSubtle,
                      width: CoFitDimens.borderWidthHairline,
                    ),
                  ),
                  child: Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: CoFitDimens.spacingXl),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: FilledButton(
                  key: const Key('public-room-join'),
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
                      : const Text('加入并进入'),
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingXs),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: TextButton(
                  onPressed: _isJoining
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    '再看看',
                    style: TextStyle(color: colors.textTertiary),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: CoFitDimens.spacingSm),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.statusDanger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

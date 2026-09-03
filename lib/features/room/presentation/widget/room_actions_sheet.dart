import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 房间操作 sheet 可返回的动作。
enum RoomSheetAction { leave, editInfo, invite, dissolve }

/// 房间操作 sheet(#17a 定稿):
/// 房主版 = 房名 + amber「房主」徽章 + 编辑房间信息 / 邀请好友 / 解散房间(红);
/// 成员版 = 房名 + 「退出房间」红字行。
/// 纯展示:选择动作后以 Navigator.pop(RoomSheetAction) 返回。
class RoomActionsSheet extends StatelessWidget {
  const RoomActionsSheet({
    required this.roomName,
    required this.isOwner,
    super.key,
  });

  final String roomName;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: CoFitDimens.spacingSm,
              children: [
                Flexible(
                  child: Text(
                    roomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: CoFitFontWeights.heading,
                    ),
                  ),
                ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CoFitDimens.spacingSm,
                      vertical: CoFitDimens.spacingXs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.typeCoreSubtle,
                      borderRadius:
                          BorderRadius.circular(CoFitDimens.radiusSm),
                      border: Border.all(
                        color: colors.statusPaused
                            .withValues(alpha: CoFitOpacities.border),
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
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            if (isOwner) ...[
              _ActionRow(
                icon: Icons.edit_outlined,
                iconColor: colors.primaryMain,
                iconBg: colors.primarySubtle,
                title: '编辑房间信息',
                subtitle: '名称 · 描述 · 可见性',
                showChevron: true,
                onTap: () =>
                    Navigator.of(context).pop(RoomSheetAction.editInfo),
              ),
              Divider(height: CoFitDimens.borderWidthHairline,
                  color: colors.borderSubtle),
              _ActionRow(
                icon: Icons.ios_share_rounded,
                iconColor: colors.typeFlexibility,
                iconBg: colors.typeFlexibilitySubtle,
                title: '邀请好友',
                subtitle: '分享房间链接',
                showChevron: true,
                onTap: () =>
                    Navigator.of(context).pop(RoomSheetAction.invite),
              ),
              Divider(height: CoFitDimens.borderWidthHairline,
                  color: colors.borderSubtle),
              _ActionRow(
                icon: Icons.close_rounded,
                iconColor: colors.statusDanger,
                iconBg: colors.statusDanger
                    .withValues(alpha: CoFitOpacities.dangerFaint),
                title: '解散房间',
                titleColor: colors.statusDanger,
                subtitle: '房主无法退出,只能解散 · 不可撤销',
                onTap: () =>
                    Navigator.of(context).pop(RoomSheetAction.dissolve),
              ),
            ] else
              _ActionRow(
                icon: Icons.logout_rounded,
                iconColor: colors.statusDanger,
                iconBg: colors.statusDanger
                    .withValues(alpha: CoFitOpacities.dangerFaint),
                title: '退出房间',
                titleColor: colors.statusDanger,
                subtitle: '退出后需重新受邀或输入房间 ID',
                onTap: () => Navigator.of(context).pop(RoomSheetAction.leave),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.showChevron = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: CoFitDimens.spacingMd,
          horizontal: CoFitDimens.spacingXs,
        ),
        child: Row(
          spacing: CoFitDimens.spacingMd,
          children: [
            Container(
              width: CoFitDimens.sizeCardIconBlock,
              height: CoFitDimens.sizeCardIconBlock,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
              ),
              child: Icon(icon,
                  size: CoFitDimens.sizeCardIcon, color: iconColor),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      color: titleColor ?? colors.textPrimary,
                      fontWeight: CoFitFontWeights.heading,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: CoFitDimens.sizeCardIcon,
                color: colors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

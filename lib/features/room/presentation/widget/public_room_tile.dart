import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 发现房间列表行(沿用 #20c 房间行的卡片语言):房名 + 简介 + 成员数 +
/// 右侧「已加入 / 查看」。纯展示组件。
class PublicRoomTile extends StatelessWidget {
  const PublicRoomTile({
    required this.name,
    required this.description,
    required this.memberCount,
    required this.joined,
    required this.onTap,
    super.key,
  });

  final String name;
  final String description;
  final int memberCount;
  final bool joined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final hasDescription = description.trim().isNotEmpty;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(CoFitDimens.spacingMd),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
            border: Border.all(
              color: joined ? colors.primaryBorder : colors.borderSubtle,
              width: CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Row(
            spacing: CoFitDimens.spacingMd,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CoFitDimens.spacingXs / 2,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: CoFitFontWeights.heading,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (hasDescription)
                      Text(
                        description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    Row(
                      spacing: CoFitDimens.spacingXs,
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: CoFitDimens.spacingMd,
                          color: colors.textTertiary,
                        ),
                        Flexible(
                          child: Text(
                            '$memberCount 名成员',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoFitDimens.spacingMd,
                  vertical: CoFitDimens.spacingXs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
                  border: Border.all(
                    color: joined ? colors.primaryBorder : colors.borderStrong,
                    width: CoFitDimens.borderWidthHairline,
                  ),
                ),
                child: Text(
                  joined ? '已加入' : '查看',
                  style: textTheme.labelSmall?.copyWith(
                    color: joined ? colors.primaryMain : colors.textSecondary,
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

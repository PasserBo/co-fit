import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 房间主界面顶栏(#6b):左=房间名 + 「X 人 · Y 人运动中」,
/// 右=「房间 n / m」 + 指示点 + 浏览/加入房间入口。
/// 纯展示;左侧需为悬浮 dock 让位由外部 padding 控制。
class RoomTopBar extends StatelessWidget {
  const RoomTopBar({
    required this.roomName,
    required this.memberCount,
    required this.activeCount,
    required this.roomIndex,
    required this.roomTotal,
    this.onBrowseRooms,
    super.key,
  });

  final String roomName;
  final int memberCount;
  final int activeCount;

  /// 当前是第几间房(1-based)。
  final int roomIndex;
  final int roomTotal;
  final VoidCallback? onBrowseRooms;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roomName,
                style: textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: CoFitDimens.spacingXs),
              Text(
                '$memberCount 人 · $activeCount 人运动中',
                style:
                    textTheme.bodySmall?.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(width: CoFitDimens.spacingMd),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CoFitDimens.spacingSm,
              children: [
                Text.rich(
                  TextSpan(
                    text: '房间 ',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                    children: [
                      TextSpan(
                        text: '$roomIndex',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primaryMain,
                          fontWeight: CoFitFontWeights.heading,
                        ),
                      ),
                      TextSpan(text: ' / $roomTotal'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onBrowseRooms,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(CoFitDimens.spacingXs),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: CoFitDimens.sizeCardIcon + CoFitDimens.spacingXs,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CoFitDimens.spacingXs),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CoFitDimens.spacingXs,
              children: [
                for (var i = 0; i < roomTotal; i++)
                  AnimatedContainer(
                    duration: kThemeAnimationDuration,
                    width: i == roomIndex - 1
                        ? CoFitDimens.sizeRoomDotActive
                        : CoFitDimens.sizeRoomDot,
                    height: CoFitDimens.sizeRoomDot,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(CoFitDimens.radiusXs),
                      color: i == roomIndex - 1
                          ? colors.primaryMain
                          : colors.textDisabled,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

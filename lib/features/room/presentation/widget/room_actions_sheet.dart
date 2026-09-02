import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 房间操作 sheet 可返回的动作。
enum RoomSheetAction { leave }

/// 房间操作 sheet(stub 协议:无定稿设计,功能优先)。
/// 纯展示:展示房间名 + 「退出房间」danger 行(owner 不显示,防房间失主)。
/// 选择动作后以 Navigator.pop(RoomSheetAction) 返回。
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
            Text(
              roomName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: CoFitDimens.spacingMd,
                ),
                child: Text(
                  '你是房主,暂不支持退出或解散房间',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              )
            else
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(RoomSheetAction.leave),
                  icon: Icon(
                    Icons.logout_rounded,
                    size: CoFitDimens.sizeCardIcon,
                    color: colors.statusDanger,
                  ),
                  label: Text(
                    '退出房间',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.statusDanger,
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

import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/user_activity_status_entity.dart';

/// HUD:当前动作徽章(#6b 简化版,倒计时环用进度环表达)。
///
/// 纯展示:只吃 [UserActivityStatusEntity],不读 provider,
/// 正式房间与登录前演示房间共用。`durationSec` / `remainingSec` 任一缺失时
/// 进度环退化为不确定态(转圈)。
class ActivityHud extends StatelessWidget {
  const ActivityHud({required this.status, super.key});

  final UserActivityStatusEntity status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final name = status.templateName ?? status.actionKey ?? '运动中';
    final duration = status.durationSec;
    final remaining = status.remainingSec;
    final progress = (duration != null && duration > 0 && remaining != null)
        ? (1 - remaining / duration).clamp(0.0, 1.0)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingMd,
        vertical: CoFitDimens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.primaryBorder,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingSm,
        children: [
          SizedBox(
            width: CoFitDimens.sizeHudRing,
            height: CoFitDimens.sizeHudRing,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: CoFitDimens.borderWidthFocus * 2,
              color: colors.primaryMain,
              backgroundColor: colors.borderStrong,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前动作',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              Text(name, style: textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}

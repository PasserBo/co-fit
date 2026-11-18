import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 演示收尾卡(纯展示):第一张卡倒计时结束后出现,邀请登录。
/// 主 CTA 走 theme 的 FilledButton(#20a 「加入房间」同款)。
class TourFinishCard extends StatelessWidget {
  const TourFinishCard({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    super.key,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(CoFitDimens.spacingLg),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.primaryBorder,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: CoFitDimens.spacingXs),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: CoFitDimens.spacingMd),
          SizedBox(
            height: CoFitDimens.sizeMinTapTarget,
            child: FilledButton(onPressed: onCta, child: Text(ctaLabel)),
          ),
        ],
      ),
    );
  }
}

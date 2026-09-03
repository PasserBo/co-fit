import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_source.dart';
import '../../domain/entity/action_type.dart';
import 'action_type_style.dart';

/// 卡面预览(纯展示,#16a 实时预览 / #16b 详情大图共用):
/// 顶部类型色条 + 图标块 + 名称 + 「类型 · 时长 · 强度」meta。
/// [large] = #16b 详情版(更宽、带来源徽章与投影)。
class CardFacePreview extends StatelessWidget {
  const CardFacePreview({
    required this.name,
    required this.type,
    required this.durationSec,
    this.intensityLabel,
    this.source,
    this.large = false,
    super.key,
  });

  final String name;
  final ActionType type;
  final int durationSec;
  final String? intensityLabel;

  /// null = 不显示来源徽章(创建表单预览态)。
  final ActionSource? source;
  final bool large;

  String get _durationLabel {
    if (durationSec < 60) {
      return '$durationSec s';
    }
    final minutes = (durationSec / 60).round();
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final typeColor = type.mainOf(colors);

    final meta = [
      type.label,
      _durationLabel,
      if (intensityLabel != null && intensityLabel!.isNotEmpty)
        intensityLabel!,
    ].join(' · ');

    // 小屏 375 下创建预览缩窄(#16a 附注)。
    final compact = MediaQuery.sizeOf(context).width <=
        CoFitDimens.sizeAuthFormMaxWidth;
    final width = large
        ? CoFitDimens.sizeCardPreviewLg
        : (compact
            ? CoFitDimens.sizeCardPreviewCompact
            : CoFitDimens.sizeCardPreview);

    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgDeep,
        borderRadius: BorderRadius.circular(
          large ? CoFitDimens.radiusLg : CoFitDimens.radiusMd,
        ),
        border: Border.all(
          color: colors.borderStrong,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: CoFitDimens.sizeCardTypeBar, color: typeColor),
          Padding(
            padding: const EdgeInsets.all(CoFitDimens.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: CoFitDimens.sizeCardIconBlock,
                      height: CoFitDimens.sizeCardIconBlock,
                      decoration: BoxDecoration(
                        color: type.subtleOf(colors),
                        borderRadius:
                            BorderRadius.circular(CoFitDimens.radiusSm),
                      ),
                      child: Icon(
                        type.icon,
                        size: CoFitDimens.sizeCardIcon,
                        color: typeColor,
                      ),
                    ),
                    if (source != null) _SourceBadge(source: source!),
                  ],
                ),
                const SizedBox(height: CoFitDimens.spacingSm),
                Text(
                  name.isEmpty ? '未命名' : name,
                  style: (large
                          ? textTheme.titleMedium
                          : textTheme.labelLarge)
                      ?.copyWith(fontWeight: CoFitFontWeights.heading),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  meta,
                  style: textTheme.labelSmall
                      ?.copyWith(color: colors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final ActionSource source;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final isCustom = source == ActionSource.custom;
    final label = switch (source) {
      ActionSource.official => '官方',
      ActionSource.custom => '自建',
      ActionSource.friendShared => '好友',
    };
    final color = switch (source) {
      ActionSource.official => colors.textTertiary,
      ActionSource.custom => colors.primaryMain,
      ActionSource.friendShared => colors.statusInfo,
    };

    return Container(
      padding: const EdgeInsets.all(CoFitDimens.spacingXs),
      decoration: BoxDecoration(
        color: isCustom ? colors.primarySubtle : colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
        border: Border.all(
          color: isCustom ? colors.primaryBorder : colors.borderStrong,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: CoFitFontWeights.label),
      ),
    );
  }
}

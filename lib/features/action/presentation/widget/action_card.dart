import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_source.dart';
import '../../domain/entity/action_template_card.dart';
import 'action_type_style.dart';

/// 动作卡片(#12b 定稿)— 全 App 复用的纯展示组件。
///
/// 解剖(2026-08-01 决议:按 #12b mock,不按 docs/README §4 底行写法):
/// 顶部类型色条 → 图标块 + 右上来源徽章(官方灰字/好友蓝字,自建卡为分享按钮)
/// → 名称 → 底行时长(自建卡追加「· 自建」)。
///
/// 宽度由父级决定(横滑列表给固定子项宽度,网格由布局计算),组件内不写死宽度。
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.card,
    this.selected = false,
    this.editing = false,
    this.onTap,
    this.onShare,
    this.onRemove,
    super.key,
  });

  final ActionTemplateCard card;

  /// 已入组态:focus 描边 + 光晕 + ✓ 角标。
  /// ⚠ 有氧卡类型色与品牌色同为 lime,选中必须靠 ✓ 角标区分,不能只靠绿框。
  final bool selected;

  /// 编辑态:右上角悬浮移除角标。
  final bool editing;

  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRemove;

  String get _durationLabel {
    final minutes = (card.defaultDurationSec / 60).round().clamp(1, 999);
    return card.source == ActionSource.custom ? '$minutes min · 自建' : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final typeMain = card.type.mainOf(colors);

    final body = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        border: Border.all(
          color: selected ? colors.borderFocus : colors.borderSubtle,
          width: selected
              ? CoFitDimens.borderWidthFocus
              : CoFitDimens.borderWidthHairline,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: colors.borderFocus
                      .withValues(alpha: CoFitOpacities.glow),
                  blurRadius: CoFitDimens.blurGlow,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: CoFitDimens.sizeCardTypeBar, color: typeMain),
          Padding(
            padding: const EdgeInsets.all(CoFitDimens.spacingSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconBlock(card: card),
                    _SourceBadge(source: card.source, onShare: onShare),
                  ],
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  card.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  _durationLabel,
                  style: textTheme.bodySmall
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(onTap: onTap, child: body),
        if (selected)
          Positioned(
            top: CoFitDimens.spacingXs,
            right: CoFitDimens.spacingXs,
            child: _CheckBadge(colors: colors),
          ),
        if (editing)
          Positioned(
            // 视觉锚点 -6px;再补偿角标自带的命中扩大 padding
            top: -(CoFitDimens.sizeRemoveBadgeOffset + CoFitDimens.spacingSm),
            right: -(CoFitDimens.sizeRemoveBadgeOffset + CoFitDimens.spacingSm),
            child: _RemoveBadge(colors: colors, onRemove: onRemove),
          ),
      ],
    );
  }
}

class _IconBlock extends StatelessWidget {
  const _IconBlock({required this.card});

  final ActionTemplateCard card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Container(
      width: CoFitDimens.sizeCardIconBlock,
      height: CoFitDimens.sizeCardIconBlock,
      decoration: BoxDecoration(
        color: card.type.subtleOf(colors),
        borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
      ),
      child: Icon(
        card.type.icon,
        size: CoFitDimens.sizeCardIcon,
        color: card.type.mainOf(colors),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, this.onShare});

  final ActionSource source;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    switch (source) {
      case ActionSource.official:
        return Text('官方',
            style: labelStyle?.copyWith(color: colors.textDisabled));
      case ActionSource.friendShared:
        return Text('好友',
            style: labelStyle?.copyWith(color: colors.statusInfo));
      case ActionSource.custom:
        // 自建卡:来源信息移到底行「· 自建」,右上角改为分享入口(#12b mock)。
        return GestureDetector(
          onTap: onShare,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(CoFitDimens.spacingXs),
            child: Icon(
              Icons.arrow_outward,
              size: CoFitDimens.sizeCardIcon,
              color: colors.primaryMain,
            ),
          ),
        );
    }
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.colors});

  final CoFitColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CoFitDimens.sizeCheckBadge,
      height: CoFitDimens.sizeCheckBadge,
      decoration: BoxDecoration(
        color: colors.primaryMain,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: CoFitDimens.sizeCardIcon,
        color: colors.primaryOn,
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.colors, this.onRemove});

  final CoFitColors colors;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // 19px 圆是设计定死的视觉尺寸,达不到 minTapTarget;
        // 用透明 padding 扩大命中区域缓解。
        padding: const EdgeInsets.all(CoFitDimens.spacingSm),
        child: Container(
          width: CoFitDimens.sizeRemoveBadge,
          height: CoFitDimens.sizeRemoveBadge,
          decoration: BoxDecoration(
            color: colors.statusDanger,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            size: CoFitDimens.sizeCardIcon,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

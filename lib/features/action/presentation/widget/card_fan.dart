import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_template_card.dart';
import 'action_type_style.dart';

/// 底部扇形手牌(#6b/#5d)。
///
/// 两种形态由 [focused] 控制(状态由外部页面持有):
/// - 收起:扇形贴底;点任意卡 → [onTapCollapsed](外部进聚焦模式)。
/// - 聚焦:卡片放大上浮(scrim 由外部绘制);点侧牌 → [onFocusCard];
///   中间卡上滑超过阈值 → [onPlay]。
///
/// 几何:卡片沿「屏下方 fanPivotRadius 处轴心」的圆弧排布,相邻夹角
/// fanSpreadDeg。位置用真实坐标计算(sin/cos),旋转只绕卡片自身中心
/// 做视觉倾斜 —— 大位移的 Transform 不参与布局会破坏命中测试。
class CardFan extends StatefulWidget {
  const CardFan({
    required this.cards,
    required this.focused,
    this.centerIndex = 0,
    this.onTapCollapsed,
    this.onFocusCard,
    this.onPlay,
    super.key,
  });

  final List<ActionTemplateCard> cards;
  final bool focused;

  /// 当前位于扇形中央的卡下标。
  final int centerIndex;
  final VoidCallback? onTapCollapsed;
  final ValueChanged<int>? onFocusCard;
  final ValueChanged<ActionTemplateCard>? onPlay;

  /// 组件总高:按聚焦态的最大占位恒定,保证聚焦卡片仍在布局盒内(可命中)。
  static const totalHeight =
      CoFitDimens.sizeFanHeight * CoFitDecor.fanFocusScale +
          CoFitDecor.fanFocusLift;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> {
  double _dragUp = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragUp = (_dragUp - details.delta.dy).clamp(0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragUp > CoFitDecor.playSwipeThreshold && widget.cards.isNotEmpty) {
      widget.onPlay?.call(
        widget.cards[widget.centerIndex.clamp(0, widget.cards.length - 1)],
      );
    }
    setState(() => _dragUp = 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final cards = widget.cards;

    if (cards.isEmpty) {
      return SizedBox(
        height: CoFitDimens.sizeFanHeight,
        child: Center(
          child: Text(
            '当前牌组还没有卡',
            style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
          ),
        ),
      );
    }

    final center = widget.centerIndex.clamp(0, cards.length - 1);
    final scale = widget.focused ? CoFitDecor.fanFocusScale : 1.0;
    final lift = widget.focused ? CoFitDecor.fanFocusLift : 0.0;
    final cardW = CoFitDimens.sizeFanCardWidth * scale;
    final cardH = CoFitDimens.sizeFanCardHeight * scale;
    // 卡片中心到扇形轴心的距离
    final radius =
        (CoFitDimens.sizeFanPivotRadius - CoFitDimens.sizeFanCardHeight / 2) *
            scale;

    return SizedBox(
      height: CardFan.totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.focused)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: CoFitDimens.spacingXl +
                      lift +
                      cardH +
                      CoFitDimens.spacingXl,
                  child: Text(
                    '↑ 上滑打出 · ${cards[center].name}',
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary),
                  ),
                ),
              for (final index in _paintOrder(cards.length, center))
                _buildCard(
                  index: index,
                  center: center,
                  centerX: centerX,
                  cardW: cardW,
                  cardH: cardH,
                  radius: radius,
                  lift: lift,
                ),
            ],
          );
        },
      ),
    );
  }

  /// 绘制顺序:离中心越远越先画(中间卡最后 = 最上层)。
  List<int> _paintOrder(int count, int center) {
    return List.generate(count, (i) => i)
      ..sort((a, b) => (b - center).abs().compareTo((a - center).abs()));
  }

  Widget _buildCard({
    required int index,
    required int center,
    required double centerX,
    required double cardW,
    required double cardH,
    required double radius,
    required double lift,
  }) {
    final card = widget.cards[index];
    final delta = index - center;
    final angle = delta * CoFitDecor.fanSpreadDeg * math.pi / 180;
    final isCenter = delta == 0;

    // 绕轴心旋转后的卡片中心位移:横向 sin,纵向下沉 (1-cos)
    final dx = radius * math.sin(angle);
    final drop = radius * (1 - math.cos(angle));
    final dragLift = isCenter && widget.focused ? _dragUp : 0.0;

    return AnimatedPositioned(
      key: ValueKey('fan_${card.id}_$index'),
      duration: CoFitMotion.fanTransition,
      curve: Curves.easeOutCubic,
      left: centerX + dx - cardW / 2,
      bottom: CoFitDimens.spacingXl + lift - drop + dragLift,
      width: cardW,
      height: cardH,
      child: AnimatedOpacity(
        duration: CoFitMotion.fanTransition,
        opacity: widget.focused && !isCenter ? CoFitDecor.fanSideOpacity : 1,
        child: GestureDetector(
          onTap: () {
            if (!widget.focused) {
              widget.onTapCollapsed?.call();
            } else if (!isCenter) {
              widget.onFocusCard?.call(index);
            }
          },
          onVerticalDragUpdate:
              isCenter && widget.focused ? _onDragUpdate : null,
          onVerticalDragEnd: isCenter && widget.focused ? _onDragEnd : null,
          behavior: HitTestBehavior.opaque,
          child: Transform.rotate(
            angle: angle,
            child: _FanCard(
              card: card,
              highlighted: isCenter && widget.focused,
            ),
          ),
        ),
      ),
    );
  }
}

/// 扇形中的迷你卡(#6b:图标块 + 名称 + 时长),尺寸由父级 Positioned 决定。
class _FanCard extends StatelessWidget {
  const _FanCard({required this.card, required this.highlighted});

  final ActionTemplateCard card;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(CoFitDimens.spacingSm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        border: Border.all(
          color: highlighted ? colors.borderFocus : colors.borderSubtle,
          width: highlighted
              ? CoFitDimens.borderWidthFocus
              : CoFitDimens.borderWidthHairline,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color:
                      colors.borderFocus.withValues(alpha: CoFitOpacities.glow),
                  blurRadius: CoFitDimens.blurGlow,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: CoFitDimens.sizeCardIcon + CoFitDimens.spacingXs,
            height: CoFitDimens.sizeCardIcon + CoFitDimens.spacingXs,
            decoration: BoxDecoration(
              color: card.type.subtleOf(colors),
              borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
            ),
            child: Icon(
              card.type.icon,
              size: CoFitDimens.sizeCardIcon,
              color: card.type.mainOf(colors),
            ),
          ),
          const SizedBox(height: CoFitDimens.spacingXs),
          Text(
            card.name,
            style: textTheme.labelMedium
                ?.copyWith(fontWeight: CoFitFontWeights.heading),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${(card.defaultDurationSec / 60).round().clamp(1, 999)} min',
            style: textTheme.labelSmall?.copyWith(color: colors.textTertiary),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

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
/// - 聚焦:卡片放大上浮(scrim 由外部绘制);点侧牌或**左右滑动**扇形
///   → [onFocusCard](滑动时整扇跟手,松手按最近一张吸附,快速甩动至少切一张);
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

  /// 横向滑动松手后的落点(纯函数):按位移折算卡位四舍五入吸附;
  /// 位移不足半张但甩动速度超过 [CoFitDecor.fanFlingVelocity] 时朝甩动方向切一张;
  /// 两端不越界。向右拖(dragX > 0)→ 中心落到下标更小的卡。
  static int resolveSwipeTarget({
    required int center,
    required int count,
    required double dragX,
    required double stepPx,
    required double velocityDx,
  }) {
    if (count <= 0) {
      return 0;
    }
    var target = (center - dragX / stepPx).round();
    if (target == center && velocityDx.abs() > CoFitDecor.fanFlingVelocity) {
      target = center - velocityDx.sign.toInt();
    }
    return target.clamp(0, count - 1);
  }

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

  /// 聚焦态横向拖动的累计位移(px,向右为正);非 0 时整扇跟手、不走过渡动画。
  double _dragX = 0;

  /// 相邻两张卡在屏幕上的横向间距(聚焦态):一个卡位 = 切一张。
  double _cardStepPx(double radius) =>
      radius * math.sin(CoFitDecor.fanSpreadDeg * math.pi / 180);

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragX += details.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details, double stepPx) {
    final count = widget.cards.length;
    final center = widget.centerIndex.clamp(0, count - 1);
    final target = CardFan.resolveSwipeTarget(
      center: center,
      count: count,
      dragX: _dragX,
      stepPx: stepPx,
      velocityDx: details.velocity.pixelsPerSecond.dx,
    );
    setState(() => _dragX = 0);
    if (target != center) {
      widget.onFocusCard?.call(target);
    }
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
    final dragging = widget.focused && _dragX != 0;
    final scale = widget.focused ? CoFitDecor.fanFocusScale : 1.0;
    final lift = widget.focused ? CoFitDecor.fanFocusLift : 0.0;
    final cardW = CoFitDimens.sizeFanCardWidth * scale;
    final cardH = CoFitDimens.sizeFanCardHeight * scale;
    // 卡片中心到扇形轴心的距离
    final radius =
        (CoFitDimens.sizeFanPivotRadius - CoFitDimens.sizeFanCardHeight / 2) *
        scale;
    final stepPx = _cardStepPx(radius);
    // 拖动中的「虚拟中心」:连续值,整扇随手指平移;两端不越界。
    final virtualCenter = dragging
        ? (center - _dragX / stepPx).clamp(0.0, (cards.length - 1).toDouble())
        : center.toDouble();

    return SizedBox(
      height: CardFan.totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;

          // 横向滑动只在聚焦态生效(收起态由房间 PageView 处理左右滑);
          // translucent:空白处仍把点击让给底下的 scrim(点击关闭聚焦)。
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: widget.focused
                ? _onHorizontalDragUpdate
                : null,
            onHorizontalDragEnd: widget.focused
                ? (details) => _onHorizontalDragEnd(details, stepPx)
                : null,
            onHorizontalDragCancel: widget.focused
                ? () => setState(() => _dragX = 0)
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.focused)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom:
                        CoFitDimens.spacingXl +
                        lift +
                        cardH +
                        CoFitDimens.spacingXl,
                    child: Text(
                      '↑ 上滑打出 · ${cards[center].name}',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                for (final index in _paintOrder(cards.length, center))
                  _buildCard(
                    index: index,
                    center: center,
                    virtualCenter: virtualCenter,
                    dragging: dragging,
                    centerX: centerX,
                    cardW: cardW,
                    cardH: cardH,
                    radius: radius,
                    lift: lift,
                  ),
              ],
            ),
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
    required double virtualCenter,
    required bool dragging,
    required double centerX,
    required double cardW,
    required double cardH,
    required double radius,
    required double lift,
  }) {
    final card = widget.cards[index];
    // 几何按虚拟中心算(拖动时连续跟手);高亮/上滑打出仍以真实中心卡为准。
    final delta = index - virtualCenter;
    final angle = delta * CoFitDecor.fanSpreadDeg * math.pi / 180;
    final isCenter = index == center;
    // 拖动中不做过渡(否则 280ms 的补间会让扇形落后于手指);松手后吸附才走动画。
    final transition = dragging ? Duration.zero : CoFitMotion.fanTransition;

    // 绕轴心旋转后的卡片中心位移:横向 sin,纵向下沉 (1-cos)
    final dx = radius * math.sin(angle);
    final drop = radius * (1 - math.cos(angle));
    final dragLift = isCenter && widget.focused ? _dragUp : 0.0;

    return AnimatedPositioned(
      key: ValueKey('fan_${card.id}_$index'),
      duration: transition,
      curve: Curves.easeOutCubic,
      left: centerX + dx - cardW / 2,
      bottom: CoFitDimens.spacingXl + lift - drop + dragLift,
      width: cardW,
      height: cardH,
      child: AnimatedOpacity(
        duration: transition,
        opacity: widget.focused && !isCenter ? CoFitDecor.fanSideOpacity : 1,
        child: GestureDetector(
          onTap: () {
            if (!widget.focused) {
              widget.onTapCollapsed?.call();
            } else if (!isCenter) {
              widget.onFocusCard?.call(index);
            }
          },
          onVerticalDragUpdate: isCenter && widget.focused
              ? _onDragUpdate
              : null,
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
                  color: colors.borderFocus.withValues(
                    alpha: CoFitOpacities.glow,
                  ),
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
            style: textTheme.labelMedium?.copyWith(
              fontWeight: CoFitFontWeights.heading,
            ),
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

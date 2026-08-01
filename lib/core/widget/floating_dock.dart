import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/cofit_colors.dart';
import '../theme/cofit_dimens.dart';

class DockDestination {
  const DockDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// 悬浮 dock(#t9 定案 9a + README §2):
/// 收起 = 只显示当前页图标(它本身就是开关);点击展开全部目的地,
/// 各目的地固定槽位(肌肉记忆);点其他目的地切换并收起;
/// [CoFitMotion.dockAutoCollapse] 无操作自动收起。没有额外的菜单按钮。
///
/// 纯展示组件:当前页与切换回调由外部(AppShell)持有,展开态为组件内部瞬时状态。
class FloatingDock extends StatefulWidget {
  const FloatingDock({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final List<DockDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// 收起态整体宽度 —— 页面给 dock 预留左上空间时用(如牌库页顶栏)。
  static const collapsedWidth =
      CoFitDimens.sizeDockItem + CoFitDimens.spacingXs * 2;

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  bool _expanded = false;
  Timer? _autoCollapse;

  @override
  void dispose() {
    _autoCollapse?.cancel();
    super.dispose();
  }

  void _restartAutoCollapse() {
    _autoCollapse?.cancel();
    _autoCollapse = Timer(CoFitMotion.dockAutoCollapse, () {
      if (mounted) {
        setState(() => _expanded = false);
      }
    });
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _restartAutoCollapse();
    } else {
      _autoCollapse?.cancel();
    }
  }

  void _select(int index) {
    if (index != widget.currentIndex) {
      widget.onSelect(index);
    }
    _autoCollapse?.cancel();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: CoFitDimens.blurOverlay,
          sigmaY: CoFitDimens.blurOverlay,
        ),
        child: Container(
          padding: const EdgeInsets.all(CoFitDimens.spacingXs),
          decoration: BoxDecoration(
            color: colors.bgOverlay,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
            border: Border.all(
              color: colors.borderStrong,
              width: CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.destinations.length; i++)
                _DockSlot(
                  destination: widget.destinations[i],
                  isCurrent: i == widget.currentIndex,
                  visible: _expanded || i == widget.currentIndex,
                  // 收起态只剩当前项,不需要槽位间距
                  gapAbove: _expanded && i > 0,
                  onTap: () {
                    if (i == widget.currentIndex) {
                      _toggle();
                    } else {
                      _select(i);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockSlot extends StatelessWidget {
  const _DockSlot({
    required this.destination,
    required this.isCurrent,
    required this.visible,
    required this.gapAbove,
    required this.onTap,
  });

  final DockDestination destination;
  final bool isCurrent;
  final bool visible;
  final bool gapAbove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return ClipRect(
      child: AnimatedContainer(
        duration: CoFitMotion.dockExpand,
        curve: Curves.easeOut,
        alignment: Alignment.bottomCenter,
        height: visible
            ? CoFitDimens.sizeDockItem + (gapAbove ? CoFitDimens.spacingSm : 0)
            : 0,
        child: AnimatedOpacity(
          duration: CoFitMotion.dockExpand,
          opacity: visible ? 1 : 0,
          child: GestureDetector(
            onTap: visible ? onTap : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(
                top: gapAbove ? CoFitDimens.spacingSm : 0,
              ),
              child: Semantics(
                label: destination.label,
                button: true,
                selected: isCurrent,
                child: Container(
                  width: CoFitDimens.sizeDockItem,
                  height: CoFitDimens.sizeDockItem,
                  decoration: isCurrent
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primarySubtle,
                          border: Border.all(
                            color: colors.primaryMain,
                            width: CoFitDimens.borderWidthHairline,
                          ),
                        )
                      : null,
                  child: Icon(
                    destination.icon,
                    size: CoFitDimens.sizeCardIcon,
                    color: isCurrent
                        ? colors.primaryMain
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

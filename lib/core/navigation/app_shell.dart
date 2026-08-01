import 'package:flutter/material.dart';

import '../theme/cofit_dimens.dart';
import '../widget/floating_dock.dart';

/// 全局导航壳(P3):IndexedStack 承载各目的地 + 左上悬浮 dock(README §2)。
/// 无底部 nav;工具页下钻用 Navigator.push + 明确返回。
///
/// 槽位固定(肌肉记忆):房间 / 牌库 / 我的。
/// 浏览/加入房间是下钻工具页,从房间主界面右上「+」压栈进入(README §2)。
class AppShell extends StatefulWidget {
  const AppShell({required this.pages, this.initialIndex = 0, super.key})
      : assert(pages.length == destinations.length);

  static const destinations = [
    DockDestination(icon: Icons.home_rounded, label: '房间'),
    DockDestination(icon: Icons.style_rounded, label: '牌库'),
    DockDestination(icon: Icons.person_rounded, label: '我的'),
  ];

  /// 与 [destinations] 一一对应。
  final List<Widget> pages;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: widget.pages),
          Positioned(
            top: safeTop + CoFitDimens.spacingSm,
            left: CoFitDimens.spacingLg,
            child: FloatingDock(
              destinations: AppShell.destinations,
              currentIndex: _index,
              onSelect: (index) => setState(() => _index = index),
            ),
          ),
        ],
      ),
    );
  }
}

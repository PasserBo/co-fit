import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/cofit_dimens.dart';
import '../widget/floating_dock.dart';
import 'app_shell_index_provider.dart';

/// 全局导航壳(P3):IndexedStack 承载各目的地 + 左上悬浮 dock(README §2)。
/// 无底部 nav;工具页下钻用 Navigator.push + 明确返回。
///
/// 槽位固定(肌肉记忆):房间 / 牌库 / 我的。
/// 浏览/加入房间是下钻工具页,从房间主界面右上「+」压栈进入(README §2)。
/// 当前 tab 由 [appShellIndexProvider] 承载(深链流程可外部驱动)。
class AppShell extends ConsumerWidget {
  const AppShell({required this.pages, super.key})
      : assert(pages.length == destinations.length);

  static const destinations = [
    DockDestination(icon: Icons.home_rounded, label: '房间'),
    DockDestination(icon: Icons.style_rounded, label: '牌库'),
    DockDestination(icon: Icons.person_rounded, label: '我的'),
  ];

  /// 与 [destinations] 一一对应。
  final List<Widget> pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final index = ref.watch(appShellIndexProvider).clamp(0, pages.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: index, children: pages),
          Positioned(
            top: safeTop + CoFitDimens.spacingSm,
            left: CoFitDimens.spacingLg,
            child: FloatingDock(
              destinations: AppShell.destinations,
              currentIndex: index,
              onSelect: (next) =>
                  ref.read(appShellIndexProvider.notifier).set(next),
            ),
          ),
        ],
      ),
    );
  }
}

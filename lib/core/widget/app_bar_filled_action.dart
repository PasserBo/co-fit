import 'package:flutter/material.dart';

import '../theme/cofit_dimens.dart';

/// AppBar `actions` 里的主按钮(如「＋ 新建」)。
///
/// 全局 filledButtonTheme 的 `minimumSize` 是 `Size.fromHeight`(宽 = 无穷,
/// 让表单里的主按钮撑满一行)。AppBar 的 actions 给的是无界宽度,直接放
/// FilledButton 会布局断言失败,release 下整条工具栏(含左上返回键)失去点击
/// ——2026-11-19「我的房间」返回键无反应即此因。AppBar 里一律用本组件。
class AppBarFilledAction extends StatelessWidget {
  const AppBarFilledAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: CoFitDimens.spacingLg),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            CoFitDimens.sizeMinTapTarget,
            CoFitDimens.sizeMinTapTarget,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: CoFitDimens.sizeCardIcon),
        label: Text(label),
      ),
    );
  }
}

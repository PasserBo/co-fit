import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import 'home_sheet_panel.dart';

/// 仅 debug 构建使用的占位模块(add-home-sheet M1):让面板有内容可看,
/// 并提供全局慢放开关,方便逐段检查上台 / 下台动画。
class HomeSheetDebugModule extends StatefulWidget {
  const HomeSheetDebugModule({super.key});

  /// 慢放倍率(只用于调试)。
  static const slowFactor = 5.0;

  @override
  State<HomeSheetDebugModule> createState() => _HomeSheetDebugModuleState();
}

class _HomeSheetDebugModuleState extends State<HomeSheetDebugModule> {
  bool get _slow => timeDilation > 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return HomeSheetModuleFrame(
      onTap: () => setState(() {
        timeDilation = _slow ? 1 : HomeSheetDebugModule.slowFactor;
      }),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '今日面板 · 占位模块',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  _slow ? '慢放已开(点此关闭)' : '点此开启动画慢放',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            _slow ? Icons.slow_motion_video : Icons.play_circle_outline,
            size: CoFitDimens.spacingXl,
            color: _slow ? colors.primaryMain : colors.textTertiary,
          ),
        ],
      ),
    );
  }
}

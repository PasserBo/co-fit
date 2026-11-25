import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home_sheet/presentation/widget/home_sheet_panel.dart';
import '../../provider/daily_goal_providers.dart';
import '../widget/daily_progress_summary.dart';

/// 运动历史页顶部的今日进度(与今日面板里的一致,不带动画与操作)。
class DailyProgressHistoryHeaderView extends ConsumerWidget {
  const DailyProgressHistoryHeaderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(dailyProgressProvider).value;
    if (progress == null) {
      return const SizedBox.shrink();
    }
    return HomeSheetModuleFrame(
      key: const ValueKey('history_daily_progress'),
      child: DailyProgressSummary(progress: progress),
    );
  }
}

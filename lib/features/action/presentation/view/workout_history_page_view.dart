import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_shell_index_provider.dart';
import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../ai_coach/presentation/view/ai_coach_page_view.dart';
import '../../../ai_coach/presentation/widget/coach_beta_badge.dart';
import '../../../ai_coach/provider/ai_coach_providers.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';
import '../../../daily_goal/presentation/view/daily_progress_history_header_view.dart';
import '../../../workout_memo/presentation/view/workout_memo_sheet_view.dart';
import '../../../workout_memo/presentation/widget/memo_editor.dart';
import '../../../workout_memo/provider/workout_memo_providers.dart';
import '../../provider/action_session_history_providers.dart';
import '../widget/workout_history_body.dart';

/// 运动历史(#18a/#18b,我的页「运动」分组 push 进入)。
/// 记录只增不改不删,只取最近 100 条,不展示房间信息(设计决议)。
class WorkoutHistoryPageView extends ConsumerWidget {
  const WorkoutHistoryPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final recordsAsync = ref.watch(recentSessionsProvider);
    final showCoach = ref.watch(aiCoachEntryVisibleProvider);
    final memoConfig = ref.watch(workoutMemoConfigProvider);
    final memoSummaries = {
      for (final memo in ref.watch(workoutMemoMapProvider).values)
        memo.sessionId: ?memoSummaryText(memo, memoConfig),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动历史'),
        actions: [
          if (showCoach)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AiCoachPageView(),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CoFitDimens.spacingXs,
                children: [Text('AI 教练'), CoachBetaBadge()],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: recordsAsync.when(
          data: (records) => records.isEmpty
              ? _EmptyHistory(
                  onGoToRoom: () {
                    ref.read(appShellIndexProvider.notifier).set(0);
                    Navigator.of(context).pop();
                  },
                )
              : WorkoutHistoryBody(
                  records: records,
                  now: DateTime.now(),
                  header: const DailyProgressHistoryHeaderView(),
                  memoSummaries: memoSummaries,
                  onRecordTap: (record) =>
                      showWorkoutMemoSheet(context, record: record),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CoFitDimens.spacingSm,
              children: [
                Text(
                  '运动记录加载失败',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textTertiary),
                ),
                OutlinedButton(
                  onPressed: () => ref.invalidate(recentSessionsProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryMain,
                    side: BorderSide(
                      color: colors.primaryBorder,
                      width: CoFitDimens.borderWidthHairline,
                    ),
                  ),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onGoToRoom});

  final VoidCallback onGoToRoom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacing3xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoFitDimens.spacingLg,
          children: [
            const IdleAvatarFigure(figureHeight: CoFitDimens.sizeFigureHero),
            Column(
              spacing: CoFitDimens.spacingXs,
              children: [
                Text(
                  '还没有运动记录',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
                Text(
                  '回到房间,打出你的第一张动作卡',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            FilledButton(onPressed: onGoToRoom, child: const Text('去房间')),
          ],
        ),
      ),
    );
  }
}

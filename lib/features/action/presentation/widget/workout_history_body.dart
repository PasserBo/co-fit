import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_session_record.dart';
import '../../domain/entity/action_type.dart';
import 'action_type_style.dart';

/// 运动历史列表体(#18a,纯展示):
/// 顶部「本周」小结卡(次数/时长 + 7 日微柱图,均由 [records] 现算)
/// + 日期分组(今天/昨天/M月d日)行列表 + 尾注「仅显示最近 100 条」。
class WorkoutHistoryBody extends StatelessWidget {
  const WorkoutHistoryBody({
    required this.records,
    required this.now,
    super.key,
  });

  /// 按 completedAt 倒序(repository 保证)。
  final List<ActionSessionRecord> records;
  final DateTime now;

  DateTime _dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

  String _groupLabel(DateTime day) {
    final today = _dayOf(now);
    if (day == today) {
      return '今天';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return '昨天';
    }
    return '${day.month}月${day.day}日';
  }

  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    // 分组(保持倒序)
    final groups = <DateTime, List<ActionSessionRecord>>{};
    for (final record in records) {
      groups.putIfAbsent(_dayOf(record.completedAt.toLocal()), () => [])
          .add(record);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CoFitDimens.spacingLg,
        CoFitDimens.spacingXs,
        CoFitDimens.spacingLg,
        CoFitDimens.spacingLg,
      ),
      children: [
        _WeekSummaryCard(records: records, now: now),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: CoFitDimens.spacingLg,
              bottom: CoFitDimens.spacingSm,
            ),
            child: Text(
              _groupLabel(entry.key),
              style: textTheme.labelMedium?.copyWith(
                color: colors.textTertiary,
                fontWeight: CoFitFontWeights.label,
              ),
            ),
          ),
          for (final record in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: CoFitDimens.spacingSm),
              child: _RecordRow(
                record: record,
                timeLabel: _timeLabel(record.completedAt),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: CoFitDimens.spacingXs),
          child: Text(
            '仅显示最近 100 条',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(color: colors.textDisabled),
          ),
        ),
      ],
    );
  }
}

class _WeekSummaryCard extends StatelessWidget {
  const _WeekSummaryCard({required this.records, required this.now});

  final List<ActionSessionRecord> records;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final today = DateTime(now.year, now.month, now.day);
    // 近 7 天(含今天),index 0 = 6 天前 … index 6 = 今天
    final dayMinutes = List<int>.filled(7, 0);
    var weekCount = 0;
    for (final record in records) {
      final completed = record.completedAt.toLocal();
      final day = DateTime(completed.year, completed.month, completed.day);
      final offset = today.difference(day).inDays;
      if (offset < 0 || offset > 6) {
        continue;
      }
      dayMinutes[6 - offset] += (record.durationSec / 60).round();
      weekCount++;
    }
    final weekMinutes = dayMinutes.fold<int>(0, (a, b) => a + b);
    final maxMinutes =
        dayMinutes.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(CoFitDimens.spacingMd),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本周',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: CoFitFontWeights.label,
                  ),
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$weekCount',
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.primaryMain,
                          fontWeight: CoFitFontWeights.heading,
                        ),
                      ),
                      TextSpan(
                        text: ' 次 · ',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      TextSpan(
                        text: '$weekMinutes',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: CoFitFontWeights.heading,
                        ),
                      ),
                      TextSpan(
                        text: ' min',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: CoFitDimens.sizeHistoryChartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: CoFitDimens.spacingXs,
              children: [
                for (var i = 0; i < 7; i++)
                  Container(
                    width: CoFitDimens.sizeHistoryChartBar,
                    height: dayMinutes[i] == 0
                        ? CoFitDimens.sizeHistoryChartBar
                        : CoFitDimens.sizeHistoryChartHeight *
                            (dayMinutes[i] / maxMinutes)
                                .clamp(0.2, 1.0),
                    decoration: BoxDecoration(
                      color: dayMinutes[i] == 0
                          ? colors.textPrimary
                              .withValues(alpha: CoFitOpacities.chartEmpty)
                          : (i == 6
                              ? colors.primaryMain
                              : colors.primaryMain.withValues(
                                  alpha: CoFitOpacities.chartDim)),
                      borderRadius:
                          BorderRadius.circular(CoFitDimens.radiusXs),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.timeLabel});

  final ActionSessionRecord record;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final type = ActionType.fromRaw(record.actionKey);
    final minutes = (record.durationSec / 60).round().clamp(1, 999);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingMd,
        vertical: CoFitDimens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Row(
        spacing: CoFitDimens.spacingMd,
        children: [
          Container(
            width: CoFitDimens.sizeCardTypeBar,
            height: CoFitDimens.sizeTypeBarHeight,
            decoration: BoxDecoration(
              color: type.mainOf(colors),
              borderRadius: BorderRadius.circular(CoFitDimens.radiusXs),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.templateName.isEmpty
                      ? record.actionKey
                      : record.templateName,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${type.label} · $minutes min',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeLabel,
            style: textTheme.labelSmall?.copyWith(color: colors.textDisabled),
          ),
        ],
      ),
    );
  }
}

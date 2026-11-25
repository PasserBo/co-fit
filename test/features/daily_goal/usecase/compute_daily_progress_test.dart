import 'package:cofit/features/daily_goal/domain/daily_progress_metric.dart';
import 'package:cofit/features/daily_goal/usecase/compute_daily_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  final today = DateTime(2026, 11, 25);

  test('只统计今天完成的', () {
    final progress = computeDailyProgress(
      records: [
        record(DateTime(2026, 11, 25, 9)),
        record(DateTime(2026, 11, 24, 23, 59)),
        record(DateTime(2026, 11, 26, 0, 1)),
      ],
      day: today,
      metric: const CardCountMetric(),
      target: 2,
    );
    expect(progress.current, 1);
    expect(progress.target, 2);
    expect(progress.unit, '张');
    expect(progress.reached, isFalse);
    expect(progress.remaining, 1);
    expect(progress.fraction, 0.5);
  });

  test('跨零点的一次运动计入完成那一天', () {
    final crossing = record(DateTime(2026, 11, 25, 0, 0, 30), durationSec: 90);
    expect(crossing.startedAt.day, 24);
    expect(
      computeDailyProgress(
        records: [crossing],
        day: today,
        metric: const CardCountMetric(),
        target: 2,
      ).current,
      1,
    );
    expect(
      computeDailyProgress(
        records: [crossing],
        day: DateTime(2026, 11, 24),
        metric: const CardCountMetric(),
        target: 2,
      ).current,
      0,
    );
  });

  test('超过目标:照实显示,进度环不超过一圈', () {
    final progress = computeDailyProgress(
      records: [for (var h = 8; h < 11; h++) record(DateTime(2026, 11, 25, h))],
      day: today,
      metric: const CardCountMetric(),
      target: 2,
    );
    expect(progress.current, 3);
    expect(progress.reached, isTrue);
    expect(progress.remaining, 0);
    expect(progress.fraction, 1);
  });

  test('换成分钟计量:同样的记录,不同的数字与单位', () {
    final progress = computeDailyProgress(
      records: [
        record(DateTime(2026, 11, 25, 9), durationSec: 90),
        record(DateTime(2026, 11, 25, 10), durationSec: 45),
      ],
      day: today,
      metric: const MinutesMetric(),
      target: 5,
    );
    expect(progress.current, 2); // 135 秒 → 2 分钟
    expect(progress.unit, '分钟');
  });

  test('localDayOf 取本地日历日的零点', () {
    expect(localDayOf(DateTime(2026, 11, 25, 23, 59)), today);
  });
}

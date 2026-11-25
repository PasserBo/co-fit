import '../../action/domain/entity/action_session_record.dart';

/// 今日进度的计量方式(design.md §1):输入今天完成的运动记录,输出一个整数。
/// 计量方式是可替换的内容——换它不动目标、进度计算与界面。
abstract interface class DailyProgressMetric {
  /// 配置里用的 id。
  String get id;

  /// 数字后面的单位(「张」「分钟」)。
  String get unit;

  int measure(List<ActionSessionRecord> todaysRecords);
}

/// 按完成的卡数计。
class CardCountMetric implements DailyProgressMetric {
  const CardCountMetric();

  @override
  String get id => DailyProgressMetricIds.cards;

  @override
  String get unit => '张';

  @override
  int measure(List<ActionSessionRecord> todaysRecords) => todaysRecords.length;
}

/// 按运动分钟数计(不足一分钟的部分舍去)。
class MinutesMetric implements DailyProgressMetric {
  const MinutesMetric();

  @override
  String get id => DailyProgressMetricIds.minutes;

  @override
  String get unit => '分钟';

  @override
  int measure(List<ActionSessionRecord> todaysRecords) {
    var seconds = 0;
    for (final record in todaysRecords) {
      seconds += record.durationSec;
    }
    return seconds ~/ Duration.secondsPerMinute;
  }
}

abstract final class DailyProgressMetricIds {
  static const cards = 'cards';
  static const minutes = 'minutes';
}

/// 内置计量方式:id → 实现。新增计量方式只需在这里登记。
const Map<String, DailyProgressMetric> dailyProgressMetricRegistry = {
  DailyProgressMetricIds.cards: CardCountMetric(),
  DailyProgressMetricIds.minutes: MinutesMetric(),
};

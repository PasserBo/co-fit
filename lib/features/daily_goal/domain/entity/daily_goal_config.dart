import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../daily_progress_metric.dart';

part 'daily_goal_config.freezed.dart';

/// 今日进度的内容配置(design.md §2):用哪种计量方式、默认目标、用户可选的目标。
/// 可远程调整;读不到或无法识别的部分回退到 [defaults]。
@freezed
abstract class DailyGoalConfig with _$DailyGoalConfig {
  const DailyGoalConfig._();

  const factory DailyGoalConfig({
    @Default(DailyProgressMetricIds.cards) String metric,
    @Default(2) int defaultTarget,
    @Default([1, 2, 3, 5, 8]) List<int> choices,
  }) = _DailyGoalConfig;

  static const defaults = DailyGoalConfig();

  /// 空串、非法 JSON、不是对象 → 整份默认值;单个字段缺失、类型不对、
  /// 数值小于 1 → 只有那个字段用默认值;不认识的计量方式 → 默认计量方式。
  /// 永不抛出。
  static DailyGoalConfig parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return defaults;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return defaults;
    }
    if (decoded is! Map) {
      return defaults;
    }
    final metric = decoded['metric'];
    final target = decoded['defaultTarget'];
    final rawChoices = decoded['choices'];
    final choices = rawChoices is List
        ? ({
            for (final value in rawChoices)
              if (value is int && value >= 1) value,
          }.toList()..sort())
        : const <int>[];
    return DailyGoalConfig(
      metric:
          metric is String && dailyProgressMetricRegistry.containsKey(metric)
          ? metric
          : defaults.metric,
      defaultTarget: target is int && target >= 1
          ? target
          : defaults.defaultTarget,
      choices: choices.isEmpty ? defaults.choices : choices,
    );
  }
}

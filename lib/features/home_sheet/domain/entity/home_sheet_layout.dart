import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_sheet_layout.freezed.dart';

/// 今日面板内置模块的 id(布局配置里用这些字符串)。
abstract final class HomeSheetModuleIds {
  static const recommendation = 'recommendation';
}

/// 今日面板的布局配置(design.md §12):模块清单与顺序、自动展开规则、
/// 补播庆祝的有效期。可远程调整;任何读不到或无法识别的部分回退到 [defaults]。
@freezed
abstract class HomeSheetLayout with _$HomeSheetLayout {
  const HomeSheetLayout._();

  const factory HomeSheetLayout({
    /// 模块 id,按显示顺序。空 = 关闭今日面板。
    @Default([HomeSheetModuleIds.recommendation]) List<String> modules,

    /// 冷启动进入房间页时展开。
    @Default(true) bool expandOnColdStart,

    /// 离开 App 超过这么多分钟后回来时展开;null = 不按离开时长展开。
    @Default(30) int? expandAfterAwayMinutes,

    /// 完成一张卡后展开(庆祝)。
    @Default(true) bool expandAfterCompletion,

    /// 没被看到的完成,超过这么多小时不再补播庆祝。
    @Default(12) int celebrationMaxAgeHours,
  }) = _HomeSheetLayout;

  static const defaults = HomeSheetLayout();

  /// 面板是否启用(至少配置了一个模块)。
  bool get enabled => modules.isNotEmpty;

  /// 解析远程配置的 JSON 字符串(design.md §12 的形状)。
  /// 空串、非法 JSON、不是对象 → 整份用默认值;单个字段缺失或类型不对 →
  /// 只有那个字段用默认值。永不抛出。
  static HomeSheetLayout parse(String? raw) {
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
    final autoExpand = decoded['autoExpand'];
    final auto = autoExpand is Map ? autoExpand : const <Object?, Object?>{};

    final modules = decoded['modules'];
    final away = auto['afterAwayMinutes'];
    final maxAge = decoded['celebrationMaxAgeHours'];
    return HomeSheetLayout(
      modules: modules is List
          ? [
              for (final id in modules)
                if (id is String && id.isNotEmpty) id,
            ]
          : defaults.modules,
      expandOnColdStart: _bool(auto['coldStart'], defaults.expandOnColdStart),
      // 显式写 null = 关闭「按离开时长展开」;缺失或类型不对 = 默认值
      expandAfterAwayMinutes:
          auto.containsKey('afterAwayMinutes') && away == null
          ? null
          : (away is int && away >= 0 ? away : defaults.expandAfterAwayMinutes),
      expandAfterCompletion: _bool(
        auto['afterCompletion'],
        defaults.expandAfterCompletion,
      ),
      celebrationMaxAgeHours: maxAge is int && maxAge >= 0
          ? maxAge
          : defaults.celebrationMaxAgeHours,
    );
  }

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;
}

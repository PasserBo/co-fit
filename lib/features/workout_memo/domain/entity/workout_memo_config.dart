import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_memo_config.freezed.dart';

/// 一个感受档位:保存的是 [key],[label] 与 [emoji] 只是展示。
@freezed
abstract class MemoFeel with _$MemoFeel {
  const factory MemoFeel({
    required String key,
    required String label,
    @Default('') String emoji,
  }) = _MemoFeel;
}

/// 运动 memo 的内容配置(design.md §3)。可远程调整;读不到或无法识别的
/// 部分回退到 [defaults]。
@freezed
abstract class WorkoutMemoConfig with _$WorkoutMemoConfig {
  const WorkoutMemoConfig._();

  const factory WorkoutMemoConfig({
    @Default([
      MemoFeel(key: 'easy', label: '轻松', emoji: '😌'),
      MemoFeel(key: 'ok', label: '刚好', emoji: '🙂'),
      MemoFeel(key: 'hard', label: '吃力', emoji: '😮‍💨'),
    ])
    List<MemoFeel> feels,

    /// 完成后多久之内今日面板还问「刚才这张」。
    @Default(30) int promptWindowMinutes,

    /// 一句话的长度上限(服务端硬上限是 500)。
    @Default(100) int noteMaxLength,
  }) = _WorkoutMemoConfig;

  static const defaults = WorkoutMemoConfig();

  /// 服务端规则里的硬上限。
  static const maxNoteLength = 500;

  Duration get promptWindow => Duration(minutes: promptWindowMinutes);

  /// 档位 key 对应的展示文字(「🙂 刚好」);配置里已经没有的 key 显示 key 本身。
  String feelText(String key) {
    for (final feel in feels) {
      if (feel.key == key) {
        return feel.emoji.isEmpty ? feel.label : '${feel.emoji} ${feel.label}';
      }
    }
    return key;
  }

  /// 空串、非法 JSON、不是对象 → 整份默认值;单个字段缺失或不合法 →
  /// 只有那个字段用默认值。永不抛出。
  static WorkoutMemoConfig parse(String? raw) {
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
    final rawFeels = decoded['feels'];
    return WorkoutMemoConfig(
      feels: rawFeels is List ? _feels(rawFeels) : defaults.feels,
      promptWindowMinutes: _int(
        decoded['promptWindowMinutes'],
        0,
        24 * 60,
        defaults.promptWindowMinutes,
      ),
      noteMaxLength: _int(
        decoded['noteMaxLength'],
        1,
        maxNoteLength,
        defaults.noteMaxLength,
      ),
    );
  }

  /// 丢掉不合法的档位与重复的 key;写了空数组 = 不问感受。
  static List<MemoFeel> _feels(List<Object?> raw) {
    final seen = <String>{};
    return [
      for (final item in raw)
        if (item is Map)
          if (item['key'] case final String key when key.isNotEmpty)
            if (item['label'] case final String label when label.isNotEmpty)
              if (seen.add(key))
                MemoFeel(
                  key: key,
                  label: label,
                  emoji: item['emoji'] is String ? item['emoji'] as String : '',
                ),
    ];
  }

  static int _int(Object? value, int min, int max, int fallback) =>
      value is int && value >= min && value <= max ? value : fallback;
}

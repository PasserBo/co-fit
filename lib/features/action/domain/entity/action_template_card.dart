import 'action_source.dart';
import 'action_type.dart';

class ActionTemplateCard {
  const ActionTemplateCard({
    required this.id,
    required this.name,
    required this.type,
    required this.rawType,
    required this.ablyActionId,
    required this.defaultDurationSec,
    this.source = ActionSource.official,
    this.intensityBaseline = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final ActionType type;

  /// Firestore `type` 字段原文(G1 决议:未知值 fallback 后原文仍保留,
  /// 且事件 actionKey 继续沿用原文,保证线上行为不变)。
  final String rawType;
  final ActionSource source;
  final String ablyActionId;
  final int defaultDurationSec;
  final Map<String, dynamic> intensityBaseline;

  String get intensityLabel {
    final label = intensityBaseline['label'];
    return label?.toString() ?? '';
  }

  ActionTemplateCard copyWith({
    String? id,
    String? name,
    ActionType? type,
    String? rawType,
    ActionSource? source,
    String? ablyActionId,
    int? defaultDurationSec,
    Map<String, dynamic>? intensityBaseline,
  }) {
    return ActionTemplateCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rawType: rawType ?? this.rawType,
      source: source ?? this.source,
      ablyActionId: ablyActionId ?? this.ablyActionId,
      defaultDurationSec: defaultDurationSec ?? this.defaultDurationSec,
      intensityBaseline: intensityBaseline ?? this.intensityBaseline,
    );
  }
}

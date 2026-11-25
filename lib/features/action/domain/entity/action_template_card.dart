import 'action_source.dart';
import 'action_type.dart';
import 'card_amount.dart';

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
    this.motionId,
    this.order = 0,
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

  /// 小人动作 clip id(P2):null 或未知 id → 按 [type] 的类型原型兜底。
  final String? motionId;

  /// 牌库排序(SSOT `firestore/card_templates.json` 的 order;自建卡 0)。
  final int order;

  /// 卡上写的「做多少」(次数 / 重量 / 距离…),可以没有,也可以有几项。
  List<CardAmount> get amounts =>
      CardAmount.listFrom(intensityBaseline['amounts']);

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
    String? motionId,
    bool clearMotionId = false,
    int? order,
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
      motionId: clearMotionId ? null : (motionId ?? this.motionId),
      order: order ?? this.order,
    );
  }
}

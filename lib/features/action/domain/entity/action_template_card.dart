class ActionTemplateCard {
  const ActionTemplateCard({
    required this.id,
    required this.name,
    required this.type,
    required this.ablyActionId,
    required this.defaultDurationSec,
    this.intensityBaseline = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String type;
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
    String? type,
    String? ablyActionId,
    int? defaultDurationSec,
    Map<String, dynamic>? intensityBaseline,
  }) {
    return ActionTemplateCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ablyActionId: ablyActionId ?? this.ablyActionId,
      defaultDurationSec: defaultDurationSec ?? this.defaultDurationSec,
      intensityBaseline: intensityBaseline ?? this.intensityBaseline,
    );
  }
}

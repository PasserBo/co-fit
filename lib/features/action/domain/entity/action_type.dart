/// 动作类型(G1 决议 2026-08-01)。
/// Firestore `type` 字段是自由字符串,repository 层经 [fromRaw] 映射到本枚举;
/// 未知值 fallback 到 [fallback],原始字符串保留在 `ActionTemplateCard.rawType`。
enum ActionType {
  strength,
  cardio,
  core,
  flexibility;

  static const fallback = ActionType.strength;

  static ActionType fromRaw(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('strength') || value.contains('力量')) {
      return ActionType.strength;
    }
    if (value.contains('cardio') || value.contains('有氧')) {
      return ActionType.cardio;
    }
    if (value.contains('core') || value.contains('核心')) {
      return ActionType.core;
    }
    if (value.contains('flex') || value.contains('柔韧')) {
      return ActionType.flexibility;
    }
    return fallback;
  }
}

import '../../action/domain/entity/action_session_record.dart';
import '../../action/domain/entity/action_template_card.dart';

/// 「今日推荐」的推荐规则(design.md §11):输入当前手牌与运动记录,
/// 输出一张**手牌里的**卡,或没有可推荐的。规则是可替换的内容,
/// 换规则只换实现,不动模块和容器。
abstract interface class RecommendCardStrategy {
  ActionTemplateCard? recommend({
    required List<ActionTemplateCard> hand,
    required List<ActionSessionRecord> history,
  });
}

/// 默认规则:手牌中最久没做过的一张;有从没做过的卡时取手牌顺序里的第一张。
class LeastRecentlyDoneStrategy implements RecommendCardStrategy {
  const LeastRecentlyDoneStrategy();

  @override
  ActionTemplateCard? recommend({
    required List<ActionTemplateCard> hand,
    required List<ActionSessionRecord> history,
  }) {
    if (hand.isEmpty) {
      return null;
    }
    final lastDone = <String, DateTime>{};
    for (final record in history) {
      final previous = lastDone[record.templateId];
      if (previous == null || record.completedAt.isAfter(previous)) {
        lastDone[record.templateId] = record.completedAt;
      }
    }
    ActionTemplateCard? oldest;
    DateTime? oldestAt;
    for (final card in hand) {
      final at = lastDone[card.id];
      if (at == null) {
        return card;
      }
      if (oldestAt == null || at.isBefore(oldestAt)) {
        oldest = card;
        oldestAt = at;
      }
    }
    return oldest;
  }
}

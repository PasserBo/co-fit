// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认
// 自建卡集合: users/{uid}/cards/{cardId}
// {cardId, name, type, ablyActionId, defaultDurationSec, intensityBaseline, createdAt, updatedAt}
// source 不落库(路径即语义,读出时恒为 ActionSource.custom)。
// 12a 创建表单设计定稿后接 UI;字段若有出入以届时决议为准。
import 'entity/action_template_card.dart';

abstract class CustomCardRepository {
  /// 当前用户的自建卡(source 恒为 custom)。
  Future<List<ActionTemplateCard>> getCustomCards();

  Future<void> createCard(ActionTemplateCard card);

  Future<void> deleteCard(String cardId);
}

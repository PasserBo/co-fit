// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认(G3 决议 2026-08-01)。
// 只存不可推导的最小事实:张数/总时长/缩略配色均由 cardIds 关联卡片现算;
// 「当前使用中牌组」是用户级偏好,放 ActionDeckRepository.activeDeckId,不放本 entity。
import 'package:freezed_annotation/freezed_annotation.dart';

part 'action_deck.freezed.dart';

@freezed
abstract class ActionDeck with _$ActionDeck {
  const factory ActionDeck({
    required String id,
    required String name,

    /// 引用 card_templates 文档 id。有序(= 扇形手牌展开顺序、拖动排序结果),允许重复。
    required List<String> cardIds,
  }) = _ActionDeck;
}

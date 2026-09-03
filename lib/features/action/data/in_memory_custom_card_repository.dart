import '../domain/custom_card_repository.dart';
import '../domain/entity/action_template_card.dart';

/// 未登录(widgetbook/测试)兜底 + usecase 单测用。
class InMemoryCustomCardRepository implements CustomCardRepository {
  final List<ActionTemplateCard> _cards = [];

  @override
  Future<List<ActionTemplateCard>> getCustomCards() async {
    return List.unmodifiable(_cards);
  }

  @override
  Future<void> createCard(ActionTemplateCard card) async {
    _cards.removeWhere((existing) => existing.id == card.id);
    _cards.add(card);
  }

  @override
  Future<void> updateCard(ActionTemplateCard card) async {
    final index = _cards.indexWhere((existing) => existing.id == card.id);
    if (index < 0) {
      throw StateError('Custom card not found: ${card.id}');
    }
    _cards[index] = card;
  }

  @override
  Future<void> deleteCard(String cardId) async {
    _cards.removeWhere((existing) => existing.id == cardId);
  }
}

import 'entity/action_template_card.dart';
import '../data/action_template_repository.dart';
import '../data/action_template_selection_repository.dart';

class SelectTemplateCardUsecase {
  SelectTemplateCardUsecase(
    this._templateRepository,
    this._selectionRepository,
  );

  final ActionTemplateRepository _templateRepository;
  final ActionTemplateSelectionRepository _selectionRepository;

  /// Input:
  /// - [templateId]: target template card id selected by user.
  ///
  /// Output:
  /// - returns the selected [ActionTemplateCard].
  ///
  /// Side effects:
  /// - persists current selected card via [ActionTemplateSelectionRepository].
  /// - does not publish room events.
  Future<ActionTemplateCard> execute({
    required String templateId,
  }) async {
    final normalizedTemplateId = templateId.trim();
    if (normalizedTemplateId.isEmpty) {
      throw ArgumentError.value(
        templateId,
        'templateId',
        'Template id must not be empty.',
      );
    }

    final cards = await _templateRepository.getTemplateCards();
    if (cards.isEmpty) {
      throw StateError('No template cards available.');
    }

    ActionTemplateCard? selectedCard;
    for (final card in cards) {
      if (card.id == normalizedTemplateId) {
        selectedCard = card;
        break;
      }
    }
    if (selectedCard == null) {
      throw StateError(
        'Template card not found for id: $normalizedTemplateId.',
      );
    }

    await _selectionRepository.setSelectedTemplateCard(selectedCard);
    return selectedCard;
  }
}

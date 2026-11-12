import 'entity/action_template_card.dart';
import '../data/action_template_repository.dart';
import '../data/action_template_selection_repository.dart';
import 'custom_card_repository.dart';

class SelectTemplateCardUsecase {
  SelectTemplateCardUsecase(
    this._templateRepository,
    this._selectionRepository, {
    CustomCardRepository? customCardRepository,
  }) : _customCardRepository = customCardRepository;

  final ActionTemplateRepository _templateRepository;
  final ActionTemplateSelectionRepository _selectionRepository;

  /// 自建卡来源(users/{uid}/cards)。官方模板里找不到时再查这里:
  /// 扇形手牌/牌组里的自建卡与官方卡同等可打出。
  final CustomCardRepository? _customCardRepository;

  /// Input:
  /// - [templateId]: target template card id selected by user.
  ///
  /// Output:
  /// - returns the selected [ActionTemplateCard].
  ///
  /// Side effects:
  /// - persists current selected card via [ActionTemplateSelectionRepository].
  /// - does not publish room events.
  Future<ActionTemplateCard> execute({required String templateId}) async {
    final normalizedTemplateId = templateId.trim();
    if (normalizedTemplateId.isEmpty) {
      throw ArgumentError.value(
        templateId,
        'templateId',
        'Template id must not be empty.',
      );
    }

    final official = await _templateRepository.getTemplateCards();
    var selectedCard = _findById(official, normalizedTemplateId);

    var custom = const <ActionTemplateCard>[];
    if (selectedCard == null && _customCardRepository != null) {
      // 自建卡读取失败按「没有自建卡」处理,不改变官方卡路径的行为。
      try {
        custom = await _customCardRepository.getCustomCards();
      } catch (_) {
        custom = const [];
      }
      selectedCard = _findById(custom, normalizedTemplateId);
    }

    if (selectedCard == null) {
      if (official.isEmpty && custom.isEmpty) {
        throw StateError('No template cards available.');
      }
      throw StateError(
        'Template card not found for id: $normalizedTemplateId.',
      );
    }

    await _selectionRepository.setSelectedTemplateCard(selectedCard);
    return selectedCard;
  }

  ActionTemplateCard? _findById(List<ActionTemplateCard> cards, String id) {
    for (final card in cards) {
      if (card.id == id) {
        return card;
      }
    }
    return null;
  }
}

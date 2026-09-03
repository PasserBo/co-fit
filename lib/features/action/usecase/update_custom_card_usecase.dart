import '../domain/custom_card_repository.dart';
import '../domain/entity/action_source.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/entity/action_type.dart';
import 'create_custom_card_usecase.dart';

/// 编辑自建卡(#16b)。校验同创建;仅自建卡可编辑(UI 层已隐藏官方卡入口,
/// 此处再兜底一次)。
class UpdateCustomCardUsecase {
  UpdateCustomCardUsecase(this._repository);

  final CustomCardRepository _repository;

  Future<ActionTemplateCard> execute({
    required ActionTemplateCard card,
    required String name,
    required String rawType,
    required int durationSec,
    Map<String, dynamic>? intensityBaseline,
  }) async {
    if (card.source != ActionSource.custom) {
      throw ArgumentError.value(
        card.source,
        'card',
        'Only custom cards can be edited.',
      );
    }
    final trimmedName = name.trim();
    final trimmedRawType = rawType.trim();
    if (trimmedName.isEmpty ||
        trimmedName.length > CreateCustomCardUsecase.nameMaxLength) {
      throw ArgumentError.value(
        name,
        'name',
        'Card name must be 1..${CreateCustomCardUsecase.nameMaxLength} '
            'characters.',
      );
    }
    if (trimmedRawType.isEmpty) {
      throw ArgumentError.value(rawType, 'rawType', 'Type must not be empty.');
    }
    if (durationSec <= 0) {
      throw ArgumentError.value(
        durationSec,
        'durationSec',
        'Duration must be positive.',
      );
    }

    final updated = card.copyWith(
      name: trimmedName,
      type: ActionType.fromRaw(trimmedRawType),
      rawType: trimmedRawType,
      ablyActionId: trimmedRawType,
      defaultDurationSec: durationSec,
      intensityBaseline: intensityBaseline ?? card.intensityBaseline,
    );
    await _repository.updateCard(updated);
    return updated;
  }
}

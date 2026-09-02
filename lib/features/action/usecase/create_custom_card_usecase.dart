import 'package:uuid/uuid.dart';

import '../domain/custom_card_repository.dart';
import '../domain/entity/action_source.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/entity/action_type.dart';

/// 创建自建卡(数据层先行;12a 表单 UI 待设计定稿)。
class CreateCustomCardUsecase {
  CreateCustomCardUsecase(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  static const int nameMaxLength = 20;

  final CustomCardRepository _repository;
  final Uuid _uuid;

  Future<ActionTemplateCard> execute({
    required String name,
    required String rawType,
    required int durationSec,
    String? ablyActionId,
    Map<String, dynamic> intensityBaseline = const {},
  }) async {
    final trimmedName = name.trim();
    final trimmedRawType = rawType.trim();
    if (trimmedName.isEmpty || trimmedName.length > nameMaxLength) {
      throw ArgumentError.value(
        name,
        'name',
        'Card name must be 1..$nameMaxLength characters.',
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

    final card = ActionTemplateCard(
      id: _uuid.v4(),
      name: trimmedName,
      type: ActionType.fromRaw(trimmedRawType),
      rawType: trimmedRawType,
      source: ActionSource.custom,
      // 自建卡无专属动画映射时,ablyActionId 沿用类型原文(动作集按类型驱动)。
      ablyActionId: (ablyActionId ?? '').trim().isEmpty
          ? trimmedRawType
          : ablyActionId!.trim(),
      defaultDurationSec: durationSec,
      intensityBaseline: intensityBaseline,
    );
    await _repository.createCard(card);
    return card;
  }
}

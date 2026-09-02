import 'package:uuid/uuid.dart';

import '../domain/action_deck_repository.dart';
import '../domain/entity/action_deck.dart';

/// 新建牌组。cardIds 允许为空(先建组后加卡)、有序、允许重复(G3 决议)。
class CreateDeckUsecase {
  CreateDeckUsecase(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const int nameMaxLength = 20;

  final ActionDeckRepository _repository;
  final Uuid _uuid;

  Future<ActionDeck> execute({
    required String name,
    List<String> cardIds = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > nameMaxLength) {
      throw ArgumentError.value(
        name,
        'name',
        'Deck name must be 1..$nameMaxLength characters.',
      );
    }
    final deck = ActionDeck(
      id: _uuid.v4(),
      name: trimmedName,
      cardIds: List.unmodifiable(cardIds),
    );
    await _repository.createDeck(deck);
    return deck;
  }
}

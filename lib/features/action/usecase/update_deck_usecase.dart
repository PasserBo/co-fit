import '../domain/action_deck_repository.dart';
import '../domain/entity/action_deck.dart';
import 'create_deck_usecase.dart';

/// 更新牌组(改名 / 增删卡 / 拖动排序统一走这里,整包覆盖 name+cardIds)。
class UpdateDeckUsecase {
  UpdateDeckUsecase(this._repository);

  final ActionDeckRepository _repository;

  Future<void> execute(ActionDeck deck) {
    final trimmedName = deck.name.trim();
    if (trimmedName.isEmpty ||
        trimmedName.length > CreateDeckUsecase.nameMaxLength) {
      throw ArgumentError.value(
        deck.name,
        'name',
        'Deck name must be 1..${CreateDeckUsecase.nameMaxLength} characters.',
      );
    }
    return _repository.updateDeck(deck.copyWith(name: trimmedName));
  }
}

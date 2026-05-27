import 'action_template_card.dart';
import 'action_template_repository.dart';

class GetTemplateCardsUsecase {
  GetTemplateCardsUsecase(this._repository);

  final ActionTemplateRepository _repository;

  /// Input:
  /// - none
  ///
  /// Output:
  /// - returns the current template card list.
  ///
  /// Side effects:
  /// - reads data from repository only, does not publish room events.
  Future<List<ActionTemplateCard>> execute() {
    return _repository.getTemplateCards();
  }
}

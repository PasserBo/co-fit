import 'entity/action_template_card.dart';
import '../data/action_template_repository.dart';

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
  Future<List<ActionTemplateCard>> execute() async {
    final cards = await _repository.getTemplateCards();
    // 按 SSOT 的 order 稳定排序(Firestore 自然序不稳定);同 order 保持原序。
    final sorted = [...cards]..sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
}

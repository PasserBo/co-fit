import '../domain/entity/action_template_card.dart';
import 'action_template_selection_repository.dart';

class InMemoryActionTemplateSelectionRepository
    implements ActionTemplateSelectionRepository {
  ActionTemplateCard? _selectedCard;

  @override
  Future<ActionTemplateCard?> getSelectedTemplateCard() async {
    return _selectedCard;
  }

  @override
  Future<void> setSelectedTemplateCard(ActionTemplateCard card) async {
    _selectedCard = card;
  }
}

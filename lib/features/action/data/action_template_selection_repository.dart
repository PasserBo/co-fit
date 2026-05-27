import 'action_template_card.dart';

abstract class ActionTemplateSelectionRepository {
  Future<void> setSelectedTemplateCard(ActionTemplateCard card);

  Future<ActionTemplateCard?> getSelectedTemplateCard();
}

import 'action_template_card.dart';

abstract class ActionTemplateRepository {
  Future<List<ActionTemplateCard>> getTemplateCards();
}

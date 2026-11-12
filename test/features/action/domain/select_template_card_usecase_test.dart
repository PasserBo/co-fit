import 'package:cofit/features/action/data/action_template_repository.dart';
import 'package:cofit/features/action/data/in_memory_action_template_selection_repository.dart';
import 'package:cofit/features/action/domain/custom_card_repository.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/action/domain/select_template_card_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

ActionTemplateCard _card(String id, ActionSource source) => ActionTemplateCard(
  id: id,
  name: id,
  type: ActionType.strength,
  rawType: 'strength',
  source: source,
  ablyActionId: id,
  defaultDurationSec: 600,
);

class _FakeTemplateRepository implements ActionTemplateRepository {
  _FakeTemplateRepository(this.cards);
  final List<ActionTemplateCard> cards;

  @override
  Future<List<ActionTemplateCard>> getTemplateCards() async => cards;
}

class _FakeCustomCardRepository implements CustomCardRepository {
  _FakeCustomCardRepository(this.cards, {this.fail = false});
  final List<ActionTemplateCard> cards;
  final bool fail;
  int reads = 0;

  @override
  Future<List<ActionTemplateCard>> getCustomCards() async {
    reads++;
    if (fail) {
      throw StateError('offline');
    }
    return cards;
  }

  @override
  Future<void> createCard(ActionTemplateCard card) async {}
  @override
  Future<void> updateCard(ActionTemplateCard card) async {}
  @override
  Future<void> deleteCard(String cardId) async {}
}

void main() {
  final official = [_card('official_1', ActionSource.official)];
  final custom = [_card('custom_1', ActionSource.custom)];

  test('official card is selected without touching custom cards', () async {
    final customRepo = _FakeCustomCardRepository(custom);
    final selection = InMemoryActionTemplateSelectionRepository();
    final usecase = SelectTemplateCardUsecase(
      _FakeTemplateRepository(official),
      selection,
      customCardRepository: customRepo,
    );

    final selected = await usecase.execute(templateId: 'official_1');

    expect(selected.id, 'official_1');
    expect(customRepo.reads, 0);
    expect((await selection.getSelectedTemplateCard())?.id, 'official_1');
  });

  test('custom card (users/{uid}/cards) can be selected and played', () async {
    final selection = InMemoryActionTemplateSelectionRepository();
    final usecase = SelectTemplateCardUsecase(
      _FakeTemplateRepository(official),
      selection,
      customCardRepository: _FakeCustomCardRepository(custom),
    );

    final selected = await usecase.execute(templateId: 'custom_1');

    expect(selected.source, ActionSource.custom);
    expect((await selection.getSelectedTemplateCard())?.id, 'custom_1');
  });

  test('unknown id still throws, even if custom cards fail to load', () async {
    final usecase = SelectTemplateCardUsecase(
      _FakeTemplateRepository(official),
      InMemoryActionTemplateSelectionRepository(),
      customCardRepository: _FakeCustomCardRepository(custom, fail: true),
    );

    expect(
      () => usecase.execute(templateId: 'custom_1'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        ),
      ),
    );
  });

  test('no cards anywhere → "No template cards available"', () async {
    final usecase = SelectTemplateCardUsecase(
      _FakeTemplateRepository(const []),
      InMemoryActionTemplateSelectionRepository(),
      customCardRepository: _FakeCustomCardRepository(const []),
    );

    expect(
      () => usecase.execute(templateId: 'x'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('No template cards'),
        ),
      ),
    );
  });
}

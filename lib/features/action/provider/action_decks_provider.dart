import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/action_deck.dart';
import 'action_deck_repository_provider.dart';

final actionDecksProvider = FutureProvider<List<ActionDeck>>((ref) {
  return ref.watch(actionDeckRepositoryProvider).getDecks();
});

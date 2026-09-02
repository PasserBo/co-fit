import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_state_provider.dart';
import '../data/firebase_action_deck_repository.dart';
import '../data/in_memory_action_deck_repository.dart';
import '../domain/action_deck_repository.dart';
import '../usecase/create_deck_usecase.dart';
import '../usecase/delete_deck_usecase.dart';
import '../usecase/seed_default_decks_usecase.dart';
import '../usecase/update_deck_usecase.dart';

/// DI:牌组仓库(A2 云端化)。
/// 已登录 → Firestore(users/{uid}/decks + profile.activeDeckId);
/// 未登录(widgetbook/测试)→ 空 in-memory 兜底。
final actionDeckRepositoryProvider = Provider<ActionDeckRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return InMemoryActionDeckRepository();
  }
  return FirebaseActionDeckRepository(userId: user.uid);
});

final seedDefaultDecksUsecaseProvider = Provider<SeedDefaultDecksUsecase>((
  ref,
) {
  return SeedDefaultDecksUsecase(ref.watch(actionDeckRepositoryProvider));
});

final createDeckUsecaseProvider = Provider<CreateDeckUsecase>((ref) {
  return CreateDeckUsecase(ref.watch(actionDeckRepositoryProvider));
});

final updateDeckUsecaseProvider = Provider<UpdateDeckUsecase>((ref) {
  return UpdateDeckUsecase(ref.watch(actionDeckRepositoryProvider));
});

final deleteDeckUsecaseProvider = Provider<DeleteDeckUsecase>((ref) {
  return DeleteDeckUsecase(ref.watch(actionDeckRepositoryProvider));
});

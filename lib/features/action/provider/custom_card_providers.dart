import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_state_provider.dart';
import '../data/firebase_custom_card_repository.dart';
import '../data/in_memory_custom_card_repository.dart';
import '../domain/custom_card_repository.dart';
import '../usecase/create_custom_card_usecase.dart';
import '../usecase/delete_custom_card_usecase.dart';
import '../usecase/update_custom_card_usecase.dart';
import 'action_deck_repository_provider.dart';

/// DI:自建卡仓库。已登录 → Firestore(users/{uid}/cards);
/// 未登录(widgetbook/测试)→ 空 in-memory 兜底。
final customCardRepositoryProvider = Provider<CustomCardRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return InMemoryCustomCardRepository();
  }
  return FirebaseCustomCardRepository(userId: user.uid);
});

final createCustomCardUsecaseProvider = Provider<CreateCustomCardUsecase>((
  ref,
) {
  return CreateCustomCardUsecase(ref.watch(customCardRepositoryProvider));
});

final updateCustomCardUsecaseProvider = Provider<UpdateCustomCardUsecase>((
  ref,
) {
  return UpdateCustomCardUsecase(ref.watch(customCardRepositoryProvider));
});

final deleteCustomCardUsecaseProvider = Provider<DeleteCustomCardUsecase>((
  ref,
) {
  return DeleteCustomCardUsecase(
    ref.watch(customCardRepositoryProvider),
    ref.watch(actionDeckRepositoryProvider),
  );
});

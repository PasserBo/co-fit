import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';
import '../data/ably_action_template_event_repository.dart';
import '../data/action_template_event_repository.dart';
import '../data/action_template_repository_provider.dart';
import '../data/action_template_selection_repository.dart';
import '../data/in_memory_action_template_selection_repository.dart';
import '../domain/complete_template_card_action_usecase.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/get_template_cards_usecase.dart';
import '../domain/select_template_card_usecase.dart';
import '../domain/start_template_card_action_usecase.dart';
import '../provider/custom_card_providers.dart';

final actionTemplateSelectionRepositoryProvider =
    Provider<ActionTemplateSelectionRepository>((ref) {
      return InMemoryActionTemplateSelectionRepository();
    });

final actionTemplateEventRepositoryProvider = Provider<ActionTemplateEventRepository>(
  (ref) {
    final runtimeNotifier = ref.read(ablyRuntimeProvider.notifier);
    return AblyActionTemplateEventRepository(
      publishEvent: (event) => runtimeNotifier.publishRoomEvent(event: event),
    );
  },
);

final getTemplateCardsUsecaseProvider = Provider<GetTemplateCardsUsecase>((ref) {
  return GetTemplateCardsUsecase(ref.watch(actionTemplateRepositoryProvider));
});

final selectTemplateCardUsecaseProvider = Provider<SelectTemplateCardUsecase>((
  ref,
) {
  return SelectTemplateCardUsecase(
    ref.watch(actionTemplateRepositoryProvider),
    ref.watch(actionTemplateSelectionRepositoryProvider),
  );
});

final startTemplateCardActionUsecaseProvider =
    Provider<StartTemplateCardActionUsecase>((ref) {
      return StartTemplateCardActionUsecase(
        ref.watch(actionTemplateSelectionRepositoryProvider),
        ref.watch(actionTemplateEventRepositoryProvider),
      );
    });

final completeTemplateCardActionUsecaseProvider =
    Provider<CompleteTemplateCardActionUsecase>((ref) {
      return CompleteTemplateCardActionUsecase(
        ref.watch(actionTemplateEventRepositoryProvider),
      );
    });

/// 全部可用卡 = 官方模板(card_templates)+ 自建卡(users/{uid}/cards)。
/// 官方卡为空仍抛错(线上必须配置);自建卡读取失败不阻塞官方卡展示。
final templateCardsProvider = FutureProvider<List<ActionTemplateCard>>((ref) async {
  final official = await ref.watch(getTemplateCardsUsecaseProvider).execute();
  List<ActionTemplateCard> custom;
  try {
    custom = await ref.watch(customCardRepositoryProvider).getCustomCards();
  } catch (_) {
    custom = const [];
  }
  return [...official, ...custom];
});

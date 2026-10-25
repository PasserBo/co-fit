import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_pending_session_repository.dart';
import '../domain/pending_session_repository.dart';
import '../usecase/recover_pending_session_usecase.dart';
import 'action_session_history_providers.dart';

final pendingSessionRepositoryProvider = Provider<PendingSessionRepository>((
  ref,
) {
  return SharedPreferencesPendingSessionRepository();
});

final recoverPendingSessionUsecaseProvider =
    Provider<RecoverPendingSessionUsecase>((ref) {
      return RecoverPendingSessionUsecase(
        ref.watch(pendingSessionRepositoryProvider),
        ref.watch(actionSessionHistoryRepositoryProvider),
      );
    });

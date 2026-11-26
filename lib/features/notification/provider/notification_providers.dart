import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_state_provider.dart';
import '../data/firebase_notification_settings_repository.dart';
import '../data/firebase_push_device_repository.dart';
import '../data/firebase_push_messaging_gateway.dart';
import '../data/firebase_workout_start_signal_repository.dart';
import '../domain/entity/notification_settings.dart';
import '../domain/entity/push_permission_status.dart';
import '../domain/notification_settings_repository.dart';
import '../domain/push_device_repository.dart';
import '../domain/push_messaging_gateway.dart';
import '../domain/workout_start_signal_repository.dart';
import '../usecase/push_permission_prompt.dart';
import '../usecase/signal_workout_start_usecase.dart';
import '../usecase/sync_push_device_usecase.dart';
import '../usecase/unregister_push_device_usecase.dart';
import '../usecase/update_notification_settings_usecase.dart';

// ── 接线(测试里覆盖这几个)───────────────────────────────────────────

final pushMessagingGatewayProvider = Provider<PushMessagingGateway>((ref) {
  return FirebasePushMessagingGateway();
});

final pushDeviceRepositoryProvider = Provider<PushDeviceRepository>((ref) {
  return FirebasePushDeviceRepository();
});

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
      return FirebaseNotificationSettingsRepository();
    });

final workoutStartSignalRepositoryProvider =
    Provider<WorkoutStartSignalRepository>((ref) {
      return FirebaseWorkoutStartSignalRepository();
    });

// ── usecase ─────────────────────────────────────────────────────────

final syncPushDeviceUsecaseProvider = Provider<SyncPushDeviceUsecase>((ref) {
  return SyncPushDeviceUsecase(
    ref.watch(pushMessagingGatewayProvider),
    ref.watch(pushDeviceRepositoryProvider),
  );
});

final unregisterPushDeviceUsecaseProvider =
    Provider<UnregisterPushDeviceUsecase>((ref) {
      return UnregisterPushDeviceUsecase(
        ref.watch(pushMessagingGatewayProvider),
        ref.watch(pushDeviceRepositoryProvider),
      );
    });

final signalWorkoutStartUsecaseProvider = Provider<SignalWorkoutStartUsecase>((
  ref,
) {
  return SignalWorkoutStartUsecase(
    ref.watch(workoutStartSignalRepositoryProvider),
  );
});

final askPushPermissionAfterWorkoutUsecaseProvider =
    Provider<AskPushPermissionAfterWorkoutUsecase>((ref) {
      return AskPushPermissionAfterWorkoutUsecase(
        ref.watch(pushMessagingGatewayProvider),
        ref.watch(syncPushDeviceUsecaseProvider),
      );
    });

final setPartnerStartPushUsecaseProvider = Provider<SetPartnerStartPushUsecase>(
  (ref) {
    return SetPartnerStartPushUsecase(
      ref.watch(notificationSettingsRepositoryProvider),
      ref.watch(pushMessagingGatewayProvider),
      ref.watch(syncPushDeviceUsecaseProvider),
    );
  },
);

final setRoomPushMutedUsecaseProvider = Provider<SetRoomPushMutedUsecase>((
  ref,
) {
  return SetRoomPushMutedUsecase(
    ref.watch(notificationSettingsRepositoryProvider),
  );
});

// ── 状态 ────────────────────────────────────────────────────────────

/// 本人的推送设置;未登录 / 加载中为默认值。
final notificationSettingsProvider = StreamProvider<NotificationSettings>((
  ref,
) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) {
    return Stream.value(NotificationSettings.defaults);
  }
  return ref
      .watch(notificationSettingsRepositoryProvider)
      .watch(userId: userId);
});

/// 系统通知权限;回到前台时由 PushLifecycleBinder 刷新(用户可能去系统设置改过)。
final pushPermissionStatusProvider = FutureProvider<PushPermissionStatus>((
  ref,
) {
  return ref.watch(pushMessagingGatewayProvider).permissionStatus();
});

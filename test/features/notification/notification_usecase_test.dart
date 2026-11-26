import 'dart:async';

import 'package:cofit/features/auth/domain/repository/auth_repository.dart';
import 'package:cofit/features/auth/usecase/sign_out_usecase.dart';
import 'package:cofit/features/notification/domain/entity/notification_settings.dart';
import 'package:cofit/features/notification/domain/entity/push_message.dart';
import 'package:cofit/features/notification/domain/entity/push_permission_status.dart';
import 'package:cofit/features/notification/domain/notification_settings_repository.dart';
import 'package:cofit/features/notification/domain/push_device_repository.dart';
import 'package:cofit/features/notification/domain/push_messaging_gateway.dart';
import 'package:cofit/features/notification/domain/push_offer_store.dart';
import 'package:cofit/features/notification/domain/workout_start_signal_repository.dart';
import 'package:cofit/features/notification/usecase/push_permission_prompt.dart';
import 'package:cofit/features/notification/usecase/signal_workout_start_usecase.dart';
import 'package:cofit/features/notification/usecase/sync_push_device_usecase.dart';
import 'package:cofit/features/notification/usecase/unregister_push_device_usecase.dart';
import 'package:cofit/features/notification/usecase/update_notification_settings_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGateway implements PushMessagingGateway {
  FakeGateway({
    this.status = PushPermissionStatus.notDetermined,
    this.grant = PushPermissionStatus.authorized,
    this.currentToken = 'tok-1',
  });

  PushPermissionStatus status;

  /// requestPermission 之后变成的状态(模拟用户点允许 / 不允许)。
  PushPermissionStatus grant;
  String? currentToken;
  int requests = 0;
  int deletes = 0;

  @override
  Future<PushPermissionStatus> permissionStatus() async => status;

  @override
  Future<PushPermissionStatus> requestPermission() async {
    requests++;
    if (status == PushPermissionStatus.notDetermined) {
      status = grant;
    }
    return status;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<void> deleteToken() async {
    deletes++;
    currentToken = null;
  }

  @override
  Future<PushMessage?> initialMessage() async => null;

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();
}

class FakeDevices implements PushDeviceRepository {
  final registered = <String>{};
  final offsets = <String, int>{};
  final log = <String>[];
  Object? unregisterError;

  @override
  Future<void> register({
    required String userId,
    required String token,
    required int utcOffsetMinutes,
  }) async {
    log.add('register $userId $token $utcOffsetMinutes');
    registered.add(token);
    offsets[token] = utcOffsetMinutes;
  }

  @override
  Future<void> unregister({
    required String userId,
    required String token,
  }) async {
    log.add('unregister $userId $token');
    if (unregisterError != null) {
      throw unregisterError!;
    }
    registered.remove(token);
  }
}

class FakeOfferStore implements PushOfferStore {
  DateTime? declinedAt;

  @override
  Future<DateTime?> lastDeclinedAt() async => declinedAt;

  @override
  Future<void> markDeclined(DateTime at) async => declinedAt = at;
}

class FakeSettings implements NotificationSettingsRepository {
  NotificationSettings value = NotificationSettings.defaults;

  @override
  Stream<NotificationSettings> watch({required String userId}) =>
      Stream.value(value);

  @override
  Future<void> setPartnerStartEnabled({
    required String userId,
    required bool enabled,
  }) async {
    value = value.copyWith(partnerStartEnabled: enabled);
  }

  @override
  Future<void> setRoomMuted({
    required String userId,
    required String roomId,
    required bool muted,
  }) async {
    final next = {...value.mutedRoomIds};
    muted ? next.add(roomId) : next.remove(roomId);
    value = value.copyWith(mutedRoomIds: next);
  }
}

class FakeSignals implements WorkoutStartSignalRepository {
  final signals = <String>[];

  @override
  Future<void> signal({
    required String userId,
    required String roomId,
    required String sessionId,
    required DateTime startedAt,
  }) async {
    signals.add('$userId/$roomId/$sessionId');
  }
}

class FakeAuth implements AuthRepository {
  FakeAuth(this.log);

  final List<String> log;

  @override
  Future<void> signOut() async => log.add('signOut');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('NotificationSettings.fromMap', () {
    test('文档不存在 = 开、无静音', () {
      final s = NotificationSettings.fromMap(null);
      expect(s.partnerStartEnabled, isTrue);
      expect(s.mutedRoomIds, isEmpty);
    });

    test('关闭与静音;非法元素忽略', () {
      final s = NotificationSettings.fromMap({
        'partnerStartEnabled': false,
        'mutedRoomIds': ['r1', 3, '', 'r2'],
      });
      expect(s.partnerStartEnabled, isFalse);
      expect(s.mutedRoomIds, {'r1', 'r2'});
      expect(s.isRoomMuted('r1'), isTrue);
    });
  });

  group('PushMessage', () {
    test('伙伴开始运动的推送带房间', () {
      expect(
        const PushMessage({
          'type': 'partner_start',
          'roomId': ' r1 ',
        }).partnerStartRoomId,
        'r1',
      );
    });

    test('别的推送 / 缺房间 → null', () {
      expect(
        const PushMessage({'type': 'other', 'roomId': 'r1'}).partnerStartRoomId,
        isNull,
      );
      expect(
        const PushMessage({'type': 'partner_start'}).partnerStartRoomId,
        isNull,
      );
    });
  });

  group('shouldOfferPushPermission', () {
    final now = DateTime(2026, 11, 26, 12);

    test('没问过、没选过以后再说 → 提示', () {
      expect(
        shouldOfferPushPermission(
          status: PushPermissionStatus.notDetermined,
          lastDeclinedAt: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('以后再说 7 天内不提示,满 7 天再提示', () {
      expect(
        shouldOfferPushPermission(
          status: PushPermissionStatus.notDetermined,
          lastDeclinedAt: now.subtract(const Duration(days: 3)),
          now: now,
        ),
        isFalse,
      );
      expect(
        shouldOfferPushPermission(
          status: PushPermissionStatus.notDetermined,
          lastDeclinedAt: now.subtract(const Duration(days: 7)),
          now: now,
        ),
        isTrue,
      );
    });

    test('系统权限问过(允许或拒绝)→ 不提示', () {
      for (final status in [
        PushPermissionStatus.authorized,
        PushPermissionStatus.denied,
      ]) {
        expect(
          shouldOfferPushPermission(
            status: status,
            lastDeclinedAt: null,
            now: now,
          ),
          isFalse,
        );
      }
    });
  });

  group('SyncPushDeviceUsecase', () {
    test('允许 → 登记当前 token', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.authorized);
      final devices = FakeDevices();
      await SyncPushDeviceUsecase(gateway, devices).execute(userId: 'u');
      expect(devices.registered, {'tok-1'});
    });

    test('登记时带上设备当地时差', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.authorized);
      final devices = FakeDevices();
      final now = DateTime.now();
      await SyncPushDeviceUsecase(
        gateway,
        devices,
        now: () => now,
      ).execute(userId: 'u');
      expect(devices.offsets['tok-1'], now.timeZoneOffset.inMinutes);
    });

    test('token 刷新时登记新 token', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.authorized);
      final devices = FakeDevices();
      await SyncPushDeviceUsecase(
        gateway,
        devices,
      ).execute(userId: 'u', token: 'tok-2');
      expect(devices.registered, {'tok-2'});
    });

    test('拒绝 → 撤掉登记(不为看不到的推送消耗冷却)', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.denied);
      final devices = FakeDevices()..registered.add('tok-1');
      await SyncPushDeviceUsecase(gateway, devices).execute(userId: 'u');
      expect(devices.registered, isEmpty);
    });

    test('没问过权限 → 什么都不做(不写不删)', () async {
      final gateway = FakeGateway();
      final devices = FakeDevices();
      await SyncPushDeviceUsecase(gateway, devices).execute(userId: 'u');
      expect(devices.log, isEmpty);
    });

    test('系统还没给 token → 什么都不做', () async {
      final gateway = FakeGateway(
        status: PushPermissionStatus.authorized,
        currentToken: null,
      );
      final devices = FakeDevices();
      await SyncPushDeviceUsecase(gateway, devices).execute(userId: 'u');
      expect(devices.log, isEmpty);
    });
  });

  group('UnregisterPushDeviceUsecase', () {
    test('撤登记并作废 token', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.authorized);
      final devices = FakeDevices()..registered.add('tok-1');
      await UnregisterPushDeviceUsecase(gateway, devices).execute(userId: 'u');
      expect(devices.registered, isEmpty);
      expect(gateway.deletes, 1);
    });

    test('撤登记失败(离线)也作废 token', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.authorized);
      final devices = FakeDevices()..unregisterError = StateError('offline');
      await expectLater(
        UnregisterPushDeviceUsecase(gateway, devices).execute(userId: 'u'),
        throwsStateError,
      );
      expect(gateway.deletes, 1);
    });
  });

  group('OfferPushPermissionUsecase', () {
    final now = DateTime(2026, 11, 26, 12);

    OfferPushPermissionUsecase build(
      FakeGateway gateway,
      FakeOfferStore store,
      FakeDevices devices,
    ) {
      return OfferPushPermissionUsecase(
        gateway,
        store,
        SyncPushDeviceUsecase(gateway, devices),
        now: () => now,
      );
    }

    test('点「打开通知」→ 弹系统请求,允许后登记设备', () async {
      final gateway = FakeGateway();
      final devices = FakeDevices();
      var shown = 0;
      final outcome = await build(gateway, FakeOfferStore(), devices).execute(
        userId: 'u',
        confirm: () async {
          shown++;
          return true;
        },
      );
      expect(shown, 1);
      expect(outcome, PushOfferOutcome.requested);
      expect(gateway.requests, 1);
      expect(devices.registered, {'tok-1'});
    });

    test('点「以后再说」→ 不弹系统请求,记下时间', () async {
      final gateway = FakeGateway();
      final store = FakeOfferStore();
      final outcome = await build(
        gateway,
        store,
        FakeDevices(),
      ).execute(userId: 'u', confirm: () async => false);
      expect(outcome, PushOfferOutcome.declined);
      expect(gateway.requests, 0);
      expect(store.declinedAt, now);
    });

    test('冷静期内 / 系统权限已问过 → 不显示提示', () async {
      var shown = 0;
      Future<bool> confirm() async {
        shown++;
        return true;
      }

      final snoozed = FakeOfferStore()
        ..declinedAt = now.subtract(const Duration(days: 1));
      expect(
        await build(
          FakeGateway(),
          snoozed,
          FakeDevices(),
        ).execute(userId: 'u', confirm: confirm),
        PushOfferOutcome.notShown,
      );
      expect(
        await build(
          FakeGateway(status: PushPermissionStatus.denied),
          FakeOfferStore(),
          FakeDevices(),
        ).execute(userId: 'u', confirm: confirm),
        PushOfferOutcome.notShown,
      );
      expect(shown, 0);
    });
  });

  group('SetPartnerStartPushUsecase', () {
    test('打开:没问过系统权限 → 请求并登记', () async {
      final gateway = FakeGateway();
      final devices = FakeDevices();
      final settings = FakeSettings()
        ..value = const NotificationSettings(partnerStartEnabled: false);
      final status = await SetPartnerStartPushUsecase(
        settings,
        gateway,
        SyncPushDeviceUsecase(gateway, devices),
      ).execute(userId: 'u', enabled: true);
      expect(settings.value.partnerStartEnabled, isTrue);
      expect(status, PushPermissionStatus.authorized);
      expect(devices.registered, {'tok-1'});
    });

    test('打开:系统权限已拒绝 → 返回 denied(界面提示去系统设置)', () async {
      final gateway = FakeGateway(status: PushPermissionStatus.denied);
      final status = await SetPartnerStartPushUsecase(
        FakeSettings(),
        gateway,
        SyncPushDeviceUsecase(gateway, FakeDevices()),
      ).execute(userId: 'u', enabled: true);
      expect(status, PushPermissionStatus.denied);
      expect(gateway.requests, 0);
    });

    test('关闭:不请求权限', () async {
      final gateway = FakeGateway();
      final settings = FakeSettings();
      await SetPartnerStartPushUsecase(
        settings,
        gateway,
        SyncPushDeviceUsecase(gateway, FakeDevices()),
      ).execute(userId: 'u', enabled: false);
      expect(settings.value.partnerStartEnabled, isFalse);
      expect(gateway.requests, 0);
    });
  });

  group('SetRoomPushMutedUsecase', () {
    test('静音 / 取消静音', () async {
      final settings = FakeSettings();
      final usecase = SetRoomPushMutedUsecase(settings);
      await usecase.execute(userId: 'u', roomId: 'r1', muted: true);
      expect(settings.value.isRoomMuted('r1'), isTrue);
      await usecase.execute(userId: 'u', roomId: 'r1', muted: false);
      expect(settings.value.isRoomMuted('r1'), isFalse);
    });
  });

  group('SignalWorkoutStartUsecase', () {
    test('写信号', () async {
      final repo = FakeSignals();
      await SignalWorkoutStartUsecase(repo).execute(
        userId: 'u',
        roomId: 'r1',
        sessionId: 's1',
        startedAt: DateTime(2026, 11, 26),
      );
      expect(repo.signals, ['u/r1/s1']);
    });

    test('空房间 id 拒绝', () {
      expect(
        () => SignalWorkoutStartUsecase(FakeSignals()).execute(
          userId: 'u',
          roomId: ' ',
          sessionId: 's1',
          startedAt: DateTime(2026, 11, 26),
        ),
        throwsArgumentError,
      );
    });
  });

  group('SignOutUsecase', () {
    test('先撤推送登记,再退出登录', () async {
      final log = <String>[];
      await SignOutUsecase(
        FakeAuth(log),
        currentUserId: () => 'u',
        beforeSignOut: [(uid) async => log.add('unregister $uid')],
      ).execute();
      expect(log, ['unregister u', 'signOut']);
    });

    test('撤登记失败或超时不阻止退出登录', () async {
      final log = <String>[];
      await SignOutUsecase(
        FakeAuth(log),
        currentUserId: () => 'u',
        hookTimeout: const Duration(milliseconds: 10),
        beforeSignOut: [
          (_) async => throw StateError('offline'),
          (_) => Completer<void>().future,
        ],
      ).execute();
      expect(log, ['signOut']);
    });
  });
}

import '../domain/entity/push_permission_status.dart';
import '../domain/push_messaging_gateway.dart';
import '../domain/push_offer_store.dart';
import 'sync_push_device_usecase.dart';

/// 选「以后再说」后多久不再出现 App 内提示(spec: 首次请求通知权限)。
const pushOfferSnooze = Duration(days: 7);

/// 现在能不能出现 App 内通知提示:系统权限还没问过,且不在「以后再说」的冷静期里。
/// 系统权限一旦问过(允许或拒绝),iOS 不会再弹请求,提示也就没有意义。
bool shouldOfferPushPermission({
  required PushPermissionStatus status,
  required DateTime? lastDeclinedAt,
  required DateTime now,
  Duration snooze = pushOfferSnooze,
}) {
  if (status != PushPermissionStatus.notDetermined) {
    return false;
  }
  return lastDeclinedAt == null || now.difference(lastDeclinedAt) >= snooze;
}

/// App 内提示的结果。
enum PushOfferOutcome {
  /// 条件不满足,没有出现提示。
  notShown,

  /// 选了「以后再说」(或关掉了提示)。
  declined,

  /// 选了打开,系统请求已弹出;[status] 是之后的权限。
  requested,
}

/// 先 App 内提示,同意后再弹系统请求;允许后立刻登记设备。
/// [confirm] 由界面提供(显示提示,返回用户是否选择打开)。
class OfferPushPermissionUsecase {
  OfferPushPermissionUsecase(
    this._gateway,
    this._store,
    this._sync, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PushMessagingGateway _gateway;
  final PushOfferStore _store;
  final SyncPushDeviceUsecase _sync;
  final DateTime Function() _now;

  /// 只判断,不显示(调用方决定要不要准备提示)。
  Future<bool> canOffer() async {
    return shouldOfferPushPermission(
      status: await _gateway.permissionStatus(),
      lastDeclinedAt: await _store.lastDeclinedAt(),
      now: _now(),
    );
  }

  Future<PushOfferOutcome> execute({
    required String userId,
    required Future<bool> Function() confirm,
  }) async {
    if (!await canOffer()) {
      return PushOfferOutcome.notShown;
    }
    final accepted = await confirm();
    if (!accepted) {
      await _store.markDeclined(_now());
      return PushOfferOutcome.declined;
    }
    final status = await _gateway.requestPermission();
    if (status.canReceive) {
      await _sync.execute(userId: userId);
    }
    return PushOfferOutcome.requested;
  }
}

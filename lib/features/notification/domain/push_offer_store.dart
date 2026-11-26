/// App 内通知提示的本机记录(按设备,不按账号)。
abstract interface class PushOfferStore {
  /// 上次选「以后再说」的时间;从没选过为 null。
  Future<DateTime?> lastDeclinedAt();

  Future<void> markDeclined(DateTime at);
}

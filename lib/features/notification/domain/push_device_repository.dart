/// 本人登记的推送设备(服务端按它发推送)。
abstract interface class PushDeviceRepository {
  /// [utcOffsetMinutes]:设备当地时间与 UTC 的差,服务端据此判断夜间不推送。
  Future<void> register({
    required String userId,
    required String token,
    required int utcOffsetMinutes,
  });

  Future<void> unregister({required String userId, required String token});
}

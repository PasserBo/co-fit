/// 本人登记的推送设备(服务端按它发推送)。
abstract interface class PushDeviceRepository {
  Future<void> register({required String userId, required String token});

  Future<void> unregister({required String userId, required String token});
}

import '../domain/push_device_repository.dart';
import '../domain/push_messaging_gateway.dart';

/// 退出登录前:撤掉本设备的登记并作废 token。
/// 撤登记失败(离线)也要作废 token——旧 token 之后发送失败,服务端会清掉登记。
class UnregisterPushDeviceUsecase {
  UnregisterPushDeviceUsecase(this._gateway, this._devices);

  final PushMessagingGateway _gateway;
  final PushDeviceRepository _devices;

  Future<void> execute({required String userId}) async {
    try {
      final token = await _gateway.token();
      if (token != null && token.isNotEmpty) {
        await _devices.unregister(userId: userId, token: token);
      }
    } finally {
      await _gateway.deleteToken();
    }
  }
}

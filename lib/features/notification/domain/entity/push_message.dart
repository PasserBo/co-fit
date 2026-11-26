/// 推送里与 App 有关的部分(data 字段)。
class PushMessage {
  const PushMessage(this.data);

  final Map<String, dynamic> data;

  /// 服务端写的类型标记(functions/src/partner_start/logic.ts 的 PUSH_TYPE)。
  static const partnerStartType = 'partner_start';

  /// 点开后要进入的房间;不是伙伴开始运动的推送、或缺 roomId 时为 null。
  String? get partnerStartRoomId {
    if (data['type'] != partnerStartType) {
      return null;
    }
    final roomId = data['roomId'];
    if (roomId is! String || roomId.trim().isEmpty) {
      return null;
    }
    return roomId.trim();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一次「加入 / 新建房间后询问通知」的请求(spec: 首次请求通知权限)。
class PushOfferRequest {
  const PushOfferRequest({required this.roomName, this.isNewRoom = false});

  /// 房间名;不知道时为空串(提示用通用说法)。
  final String roomName;

  /// 刚新建的房间:还没有伙伴,文案说「伙伴加入后」。
  final bool isNewRoom;
}

/// 加入 / 新建流程成功后写入,由 PushLifecycleBinder 在流程的界面收起后消费,
/// 出现 App 内通知提示。
class PushOfferRequestNotifier extends Notifier<PushOfferRequest?> {
  @override
  PushOfferRequest? build() => null;

  void requestAfterJoin(String roomName) {
    state = PushOfferRequest(roomName: roomName);
  }

  void requestAfterCreate(String roomName) {
    state = PushOfferRequest(roomName: roomName, isNewRoom: true);
  }

  void clear() {
    state = null;
  }
}

final pushOfferRequestProvider =
    NotifierProvider<PushOfferRequestNotifier, PushOfferRequest?>(
      PushOfferRequestNotifier.new,
    );

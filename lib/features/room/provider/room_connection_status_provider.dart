import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';

/// 房间实时通道的用户可见状态(把 Ably 连接态 + 频道态折叠成四档)。
/// live 时不显示任何提示;其余三档由 RoomConnectionBanner 呈现。
enum RoomConnectionStatus {
  /// 已连接且房间频道已 attach。
  live,

  /// 首次连接 / 短暂断线自动重连中(Ably connecting / disconnected / attaching)。
  connecting,

  /// 长时间离线(Ably suspended):恢复网络后 SDK 会自动重连。
  offline,

  /// 不可恢复:未配置 key、连接 failed/closed、频道 failed。
  unavailable,
}

/// 纯函数:便于单测,provider 只做接线。
RoomConnectionStatus roomConnectionStatusOf(
  AblyRuntimeState runtime,
  String roomId,
) {
  switch (runtime.runtimePhase) {
    case AblyRuntimePhase.unconfigured:
      return RoomConnectionStatus.unavailable;
    case AblyRuntimePhase.idle:
      return RoomConnectionStatus.connecting;
    case AblyRuntimePhase.active:
      break;
  }

  switch (runtime.connectionState) {
    case ably.ConnectionState.failed:
    case ably.ConnectionState.closed:
    case ably.ConnectionState.closing:
      return RoomConnectionStatus.unavailable;
    case ably.ConnectionState.suspended:
      return RoomConnectionStatus.offline;
    case ably.ConnectionState.initialized:
    case ably.ConnectionState.connecting:
    case ably.ConnectionState.disconnected:
    case null:
      return RoomConnectionStatus.connecting;
    case ably.ConnectionState.connected:
      break;
  }

  switch (runtime.channelStates[roomId]) {
    case ably.ChannelState.failed:
      return RoomConnectionStatus.unavailable;
    case ably.ChannelState.attached:
      return RoomConnectionStatus.live;
    // 频道尚未订阅/attach 中:连接已通,按 connecting 呈现
    case ably.ChannelState.initialized:
    case ably.ChannelState.attaching:
    case ably.ChannelState.detaching:
    case ably.ChannelState.detached:
    case ably.ChannelState.suspended:
    case null:
      return RoomConnectionStatus.connecting;
  }
}

final roomConnectionStatusProvider =
    Provider.family<RoomConnectionStatus, String>((ref, roomId) {
      final runtime = ref.watch(ablyRuntimeProvider);
      return roomConnectionStatusOf(runtime, roomId);
    });

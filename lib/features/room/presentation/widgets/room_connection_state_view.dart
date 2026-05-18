import 'package:flutter/material.dart';

import '../../../../firestore/ably_state_machine.dart';
import 'room_connection_status_utils.dart';
import 'room_status_chip.dart';

class RoomConnectionStateView extends StatelessWidget {
  const RoomConnectionStateView({
    required this.runtime,
    required this.activeRoomId,
    super.key,
  });

  final AblyRuntimeState runtime;
  final String? activeRoomId;

  @override
  Widget build(BuildContext context) {
    final roomChannelState = activeRoomId == null
        ? null
        : runtime.channelStates[activeRoomId!];
    final connectionLabel = roomConnectionLabel(runtime);
    final connectionColor = roomConnectionColor(runtime, context);
    final channelLabel = roomChannelLabel(roomChannelState, activeRoomId);
    final channelColor = roomChannelColor(roomChannelState, activeRoomId, context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        RoomStatusChip(
          label: 'Ably: $connectionLabel',
          color: connectionColor,
        ),
        RoomStatusChip(
          label: 'Room Channel: $channelLabel',
          color: channelColor,
        ),
      ],
    );
  }
}

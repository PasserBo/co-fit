import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/material.dart';

import '../../../../firestore/ably_state_machine.dart';

String roomConnectionLabel(AblyRuntimeState runtime) {
  switch (runtime.runtimePhase) {
    case AblyRuntimePhase.idle:
      return 'idle';
    case AblyRuntimePhase.unconfigured:
      return 'unconfigured';
    case AblyRuntimePhase.active:
      final state = runtime.connectionState;
      if (state == null) {
        return 'unknown';
      }
      return state.name;
  }
}

Color roomConnectionColor(AblyRuntimeState runtime, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  if (runtime.runtimePhase == AblyRuntimePhase.unconfigured) {
    return scheme.error;
  }
  final state = runtime.connectionState;
  if (state == ably.ConnectionState.connected) {
    return Colors.green;
  }
  if (state == ably.ConnectionState.connecting ||
      state == ably.ConnectionState.disconnected) {
    return Colors.orange;
  }
  if (state == ably.ConnectionState.failed) {
    return scheme.error;
  }
  return Colors.blueGrey;
}

String roomChannelLabel(ably.ChannelState? state, String? roomId) {
  if (roomId == null) {
    return 'n/a';
  }
  return state?.name ?? 'unknown';
}

Color roomChannelColor(
  ably.ChannelState? state,
  String? roomId,
  BuildContext context,
) {
  final scheme = Theme.of(context).colorScheme;
  if (roomId == null) {
    return Colors.blueGrey;
  }
  if (state == ably.ChannelState.attached) {
    return Colors.green;
  }
  if (state == ably.ChannelState.attaching ||
      state == ably.ChannelState.detaching) {
    return Colors.orange;
  }
  if (state == ably.ChannelState.failed) {
    return scheme.error;
  }
  return Colors.blueGrey;
}

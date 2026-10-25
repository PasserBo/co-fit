import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:cofit/features/room/provider/room_connection_status_provider.dart';
import 'package:cofit/firestore/ably_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

AblyRuntimeState _state({
  AblyRuntimePhase phase = AblyRuntimePhase.active,
  ably.ConnectionState? connection,
  ably.ChannelState? channel,
}) {
  return AblyRuntimeState(
    isConfigured: phase != AblyRuntimePhase.unconfigured,
    runtimePhase: phase,
    connectionState: connection,
    channelStates: channel == null ? const {} : {'r1': channel},
  );
}

void main() {
  test('unconfigured → unavailable', () {
    expect(
      roomConnectionStatusOf(
        _state(phase: AblyRuntimePhase.unconfigured),
        'r1',
      ),
      RoomConnectionStatus.unavailable,
    );
  });

  test('idle (not yet initialized) → connecting', () {
    expect(
      roomConnectionStatusOf(_state(phase: AblyRuntimePhase.idle), 'r1'),
      RoomConnectionStatus.connecting,
    );
  });

  test('connected + attached → live', () {
    expect(
      roomConnectionStatusOf(
        _state(
          connection: ably.ConnectionState.connected,
          channel: ably.ChannelState.attached,
        ),
        'r1',
      ),
      RoomConnectionStatus.live,
    );
  });

  test('connected but channel not attached yet → connecting', () {
    expect(
      roomConnectionStatusOf(
        _state(connection: ably.ConnectionState.connected),
        'r1',
      ),
      RoomConnectionStatus.connecting,
    );
  });

  test('disconnected (transient) → connecting; suspended → offline', () {
    expect(
      roomConnectionStatusOf(
        _state(connection: ably.ConnectionState.disconnected),
        'r1',
      ),
      RoomConnectionStatus.connecting,
    );
    expect(
      roomConnectionStatusOf(
        _state(connection: ably.ConnectionState.suspended),
        'r1',
      ),
      RoomConnectionStatus.offline,
    );
  });

  test('failed connection or failed channel → unavailable', () {
    expect(
      roomConnectionStatusOf(
        _state(connection: ably.ConnectionState.failed),
        'r1',
      ),
      RoomConnectionStatus.unavailable,
    );
    expect(
      roomConnectionStatusOf(
        _state(
          connection: ably.ConnectionState.connected,
          channel: ably.ChannelState.failed,
        ),
        'r1',
      ),
      RoomConnectionStatus.unavailable,
    );
  });
}

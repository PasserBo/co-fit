import 'package:ably_flutter/ably_flutter.dart' as ably;

class AblyService {
  AblyService({
    required String apiKey,
    required String clientId,
  }) : _realtime = ably.Realtime(
          options: ably.ClientOptions(
            key: apiKey,
            clientId: clientId,
            autoConnect: false,
          ),
        );

  final ably.Realtime _realtime;

  ably.Realtime get realtime => _realtime;

  Future<void> connect() async {
    _realtime.connect();
  }

  Future<void> disconnect() async {
    _realtime.close();
  }

  Stream<ably.ConnectionStateChange> watchConnectionState() {
    return _realtime.connection.on();
  }

  Future<void> dispose() async {
    _realtime.close();
  }
}

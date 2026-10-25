import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_session_snapshot.freezed.dart';

/// 本机正在进行的运动会话快照(本地持久化,用于 app 被杀后恢复)。
/// 只存重建一条 ActionSessionRecord 所需的最小事实;完成时刻 = startedAt + durationSec。
@freezed
abstract class PendingSessionSnapshot with _$PendingSessionSnapshot {
  const PendingSessionSnapshot._();

  const factory PendingSessionSnapshot({
    required String sessionId,
    required String roomId,
    required String userId,
    required String templateId,
    required String templateName,
    required String actionKey,
    required int durationSec,
    required DateTime startedAt,
  }) = _PendingSessionSnapshot;

  DateTime get endsAt => startedAt.add(Duration(seconds: durationSec));

  bool isExpiredAt(DateTime now) => !now.isBefore(endsAt);

  int remainingSecAt(DateTime now) {
    final seconds = endsAt.difference(now).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  Map<String, dynamic> toMap() => {
    'sessionId': sessionId,
    'roomId': roomId,
    'userId': userId,
    'templateId': templateId,
    'templateName': templateName,
    'actionKey': actionKey,
    'durationSec': durationSec,
    'startedAt': startedAt.toUtc().toIso8601String(),
  };

  static PendingSessionSnapshot? fromMap(Object? source) {
    if (source is! Map) {
      return null;
    }
    final startedAt = DateTime.tryParse('${source['startedAt'] ?? ''}');
    final durationSec = int.tryParse('${source['durationSec'] ?? ''}');
    final sessionId = '${source['sessionId'] ?? ''}';
    if (startedAt == null || durationSec == null || sessionId.isEmpty) {
      return null;
    }
    return PendingSessionSnapshot(
      sessionId: sessionId,
      roomId: '${source['roomId'] ?? ''}',
      userId: '${source['userId'] ?? ''}',
      templateId: '${source['templateId'] ?? ''}',
      templateName: '${source['templateName'] ?? ''}',
      actionKey: '${source['actionKey'] ?? ''}',
      durationSec: durationSec,
      startedAt: startedAt.toLocal(),
    );
  }
}

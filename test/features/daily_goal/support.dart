import 'package:cofit/features/action/domain/entity/action_session_record.dart';

ActionSessionRecord record(DateTime completedAt, {int durationSec = 60}) {
  return ActionSessionRecord(
    sessionId: 's-${completedAt.microsecondsSinceEpoch}',
    roomId: 'room',
    userId: 'me',
    templateId: 'squat',
    templateName: '深蹲',
    actionKey: 'squat',
    durationSec: durationSec,
    startedAt: completedAt.subtract(Duration(seconds: durationSec)),
    completedAt: completedAt,
  );
}

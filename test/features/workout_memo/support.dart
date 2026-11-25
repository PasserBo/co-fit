import 'package:cofit/features/action/domain/entity/action_session_record.dart';

ActionSessionRecord record(
  DateTime completedAt, {
  String id = '',
  String name = '深蹲',
  String actionKey = 'strength',
}) {
  return ActionSessionRecord(
    sessionId: id.isEmpty ? 's-${completedAt.microsecondsSinceEpoch}' : id,
    roomId: 'room',
    userId: 'me',
    templateId: 'squat',
    templateName: name,
    actionKey: actionKey,
    durationSec: 60,
    startedAt: completedAt.subtract(const Duration(seconds: 60)),
    completedAt: completedAt,
  );
}

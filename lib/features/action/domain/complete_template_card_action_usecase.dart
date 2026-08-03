import 'package:uuid/uuid.dart';

import '../../room/domain/entity/room_event.dart';
import '../data/action_template_event_repository.dart';
import 'entity/action_template_card.dart';
import 'entity/template_card_session.dart';

/// 结束一次模板卡会话:发布 `action_completed` 房间事件(与 started 同 sessionId)。
class CompleteTemplateCardActionUsecase {
  CompleteTemplateCardActionUsecase(
    this._eventRepository, {
    Uuid? uuid,
    DateTime Function()? now,
  })  : _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now;

  final ActionTemplateEventRepository _eventRepository;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> execute({
    required TemplateCardSession session,
    required ActionTemplateCard card,
  }) async {
    final event = RoomEvent(
      eventId: _uuid.v4(),
      roomId: session.roomId,
      userId: session.userId,
      type: RoomEventType.actionCompleted,
      timestamp: _now(),
      payload: RoomEventPayload(
        schemaVersion: 1,
        actionKey: card.rawType,
        durationSec: card.defaultDurationSec,
        remainingSec: 0,
        sessionId: session.sessionId,
        customData: {
          'templateId': card.id,
          'templateName': card.name,
          'ablyActionId': card.ablyActionId,
          'intensityLabel': card.intensityLabel,
        },
      ),
    );
    await _eventRepository.publishRoomEvent(event: event);
  }
}

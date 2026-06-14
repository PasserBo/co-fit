import 'package:uuid/uuid.dart';

import '../../room/domain/entity/room_event.dart';
import 'entity/action_template_card.dart';
import '../data/action_template_event_repository.dart';
import '../data/action_template_selection_repository.dart';
import 'entity/template_card_session.dart';

class StartTemplateCardActionUsecase {
  StartTemplateCardActionUsecase(
    this._selectionRepository,
    this._eventRepository, {
    Uuid? uuid,
    DateTime Function()? now,
  }) : _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  final ActionTemplateSelectionRepository _selectionRepository;
  final ActionTemplateEventRepository _eventRepository;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// Input:
  /// - [roomId]: the room where the action starts.
  /// - [userId]: the current operator user id.
  ///
  /// Output:
  /// - returns a [TemplateCardSession] representing the started session.
  ///
  /// Side effects:
  /// - reads selected template card from repository.
  /// - publishes one `action_started` room event.
  Future<TemplateCardSession> execute({
    required String roomId,
    required String userId,
  }) async {
    final normalizedRoomId = roomId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedRoomId.isEmpty) {
      throw ArgumentError.value(roomId, 'roomId', 'Room id must not be empty.');
    }
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
    }

    final selectedCard = await _selectionRepository.getSelectedTemplateCard();
    if (selectedCard == null) {
      throw StateError('No selected template card.');
    }

    final startedAt = _now();
    final sessionId = _uuid.v4();
    final event = _buildStartedEvent(
      roomId: normalizedRoomId,
      userId: normalizedUserId,
      sessionId: sessionId,
      startedAt: startedAt,
      card: selectedCard,
    );

    await _eventRepository.publishRoomEvent(event: event);

    return TemplateCardSession(
      templateId: selectedCard.id,
      sessionId: sessionId,
      roomId: normalizedRoomId,
      userId: normalizedUserId,
      status: TemplateCardSessionStatus.started,
      startedAt: startedAt,
    );
  }

  RoomEvent _buildStartedEvent({
    required String roomId,
    required String userId,
    required String sessionId,
    required DateTime startedAt,
    required ActionTemplateCard card,
  }) {
    return RoomEvent(
      eventId: _uuid.v4(),
      roomId: roomId,
      userId: userId,
      type: RoomEventType.actionStarted,
      timestamp: startedAt,
      payload: RoomEventPayload(
        schemaVersion: 1,
        actionKey: card.type,
        durationSec: card.defaultDurationSec,
        remainingSec: card.defaultDurationSec,
        sessionId: sessionId,
        customData: {
          'templateId': card.id,
          'templateName': card.name,
          'ablyActionId': card.ablyActionId,
          'intensityLabel': card.intensityLabel,
        },
      ),
    );
  }
}

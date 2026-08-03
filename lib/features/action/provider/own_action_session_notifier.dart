import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';
import '../../room/domain/entity/user_activity_status_entity.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/entity/template_card_session.dart';
import '../presentation/action_template_usecase_provider.dart';

/// 自己的运动会话生命周期(实测问题 1 的修复):
/// play → 发布 started 事件 + **写 presence.activity(active)**(晚进房者的快照来源)
///       + 本地倒计时;
/// 计时结束 → 发布 completed 事件 + presence.activity 回 idle。
///
/// 两条通道输出同一形状(UserActivityStatusEntity 的 map),
/// 与事件流折叠(RoomActivitySnapshot)天然互补。
class OwnActionSessionNotifier extends Notifier<TemplateCardSession?> {
  Timer? _completionTimer;
  ActionTemplateCard? _activeCard;

  @override
  TemplateCardSession? build() {
    ref.onDispose(() => _completionTimer?.cancel());
    return null;
  }

  Future<void> play({
    required ActionTemplateCard card,
    required String roomId,
    required String userId,
  }) async {
    await ref
        .read(selectTemplateCardUsecaseProvider)
        .execute(templateId: card.id);
    final session = await ref
        .read(startTemplateCardActionUsecaseProvider)
        .execute(roomId: roomId, userId: userId);

    await _updatePresence(
      roomId: roomId,
      userId: userId,
      status: UserActivityStatusEntity(
        activityState: UserActivityState.active,
        actionKey: card.rawType,
        durationSec: card.defaultDurationSec,
        remainingSec: card.defaultDurationSec,
        sessionId: session.sessionId,
        templateId: card.id,
        templateName: card.name,
        updatedAtEpochMs: session.startedAt.millisecondsSinceEpoch,
      ),
    );

    _completionTimer?.cancel();
    _completionTimer = Timer(
      Duration(seconds: card.defaultDurationSec),
      () => unawaited(complete()),
    );
    _activeCard = card;
    state = session;
  }

  /// 会话结束(计时到点;也可由未来的「提前结束」入口调用)。
  Future<void> complete() async {
    final session = state;
    final card = _activeCard;
    _completionTimer?.cancel();
    if (session == null || card == null) {
      return;
    }
    state = null;
    _activeCard = null;

    await ref
        .read(completeTemplateCardActionUsecaseProvider)
        .execute(session: session, card: card);
    await _updatePresence(
      roomId: session.roomId,
      userId: session.userId,
      status: UserActivityStatusEntity(
        activityState: UserActivityState.idle,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _updatePresence({
    required String roomId,
    required String userId,
    required UserActivityStatusEntity status,
  }) {
    return ref.read(ablyRuntimeProvider.notifier).updatePresenceData(
      roomId: roomId,
      data: {
        'userId': userId,
        'activity': userActivityStatusEntityToMap(status),
      },
    );
  }
}

final ownActionSessionProvider =
    NotifierProvider<OwnActionSessionNotifier, TemplateCardSession?>(
  OwnActionSessionNotifier.new,
);

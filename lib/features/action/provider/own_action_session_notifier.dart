import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';
import '../../room/domain/entity/user_activity_status_entity.dart';
import '../../room/provider/own_activity_status_provider.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/entity/pending_session_snapshot.dart';
import '../domain/entity/template_card_session.dart';
import '../presentation/action_template_usecase_provider.dart';
import '../usecase/recover_pending_session_usecase.dart';
import 'action_session_history_providers.dart';
import 'pending_session_providers.dart';

/// 自己的运动会话生命周期(实测问题 1 的修复):
/// play → 发布 started 事件 + **写 presence.activity(active)**(晚进房者的快照来源)
///       + 本地倒计时;
/// 计时结束 → 发布 completed 事件 + presence.activity 回 idle。
///
/// 两条通道输出同一形状(UserActivityStatusEntity 的 map),
/// 与事件流折叠(RoomActivitySnapshot)天然互补。
///
/// 本地持久化:play 时写 PendingSessionSnapshot,complete 时清;
/// 冷启动经 [recoverPending] 补记过期会话或恢复进行中的倒计时
/// (修复「会话中 app 被杀 → 打卡记录丢失」)。
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

    _armTimer(Duration(seconds: card.defaultDurationSec));
    _activeCard = card;
    state = session;

    // 持久化失败不影响会话(只是失去被杀后的恢复能力)。
    unawaited(
      ref
          .read(pendingSessionRepositoryProvider)
          .save(
            PendingSessionSnapshot(
              sessionId: session.sessionId,
              roomId: roomId,
              userId: userId,
              templateId: card.id,
              templateName: card.name,
              actionKey: card.rawType,
              durationSec: card.defaultDurationSec,
              startedAt: session.startedAt,
            ),
          )
          .catchError((Object error) {
            debugPrint('pendingSession save failed: $error');
          }),
    );
  }

  void _armTimer(Duration remaining) {
    _completionTimer?.cancel();
    _completionTimer = Timer(remaining, () => unawaited(complete()));
  }

  /// 冷启动恢复(bootstrap 在房间订阅完成后调用):
  /// 过期 → usecase 已补记,刷新历史;进行中 → 重建 state + 剩余倒计时 + presence。
  /// 卡片已被删除(自建卡)时无法恢复,直接放弃快照。
  Future<void> recoverPending({
    required String userId,
    required List<ActionTemplateCard> cards,
  }) async {
    final result = await ref
        .read(recoverPendingSessionUsecaseProvider)
        .execute(userId: userId);
    switch (result) {
      case NoPendingSession():
        return;
      case ExpiredSessionRecorded():
        ref.invalidate(recentSessionsProvider);
        return;
      case SessionStillRunning(:final snapshot):
        if (state != null) {
          return; // 本进程已有会话,不覆盖
        }
        ActionTemplateCard? card;
        for (final c in cards) {
          if (c.id == snapshot.templateId) {
            card = c;
            break;
          }
        }
        if (card == null) {
          await ref.read(pendingSessionRepositoryProvider).clear();
          return;
        }
        final now = DateTime.now();
        final remaining = snapshot.remainingSecAt(now);
        _activeCard = card;
        state = TemplateCardSession(
          templateId: snapshot.templateId,
          sessionId: snapshot.sessionId,
          roomId: snapshot.roomId,
          userId: snapshot.userId,
          status: TemplateCardSessionStatus.started,
          startedAt: snapshot.startedAt,
        );
        _armTimer(Duration(seconds: remaining));
        await _updatePresence(
          roomId: snapshot.roomId,
          userId: userId,
          status: UserActivityStatusEntity(
            activityState: UserActivityState.active,
            actionKey: snapshot.actionKey,
            durationSec: snapshot.durationSec,
            remainingSec: remaining,
            sessionId: snapshot.sessionId,
            templateId: snapshot.templateId,
            templateName: snapshot.templateName,
            updatedAtEpochMs: now.millisecondsSinceEpoch,
          ),
        );
    }
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
    unawaited(
      ref.read(pendingSessionRepositoryProvider).clear().catchError((Object e) {
        debugPrint('pendingSession clear failed: $e');
      }),
    );

    await ref
        .read(completeTemplateCardActionUsecaseProvider)
        .execute(session: session, card: card);
    // 打卡记录落库:fire-and-forget,失败不阻塞事件/presence 流。
    // app 在会话中被杀的情况由 recoverPending 在下次启动补记。
    unawaited(
      ref
          .read(recordCompletedSessionUsecaseProvider)
          .execute(session: session, card: card)
          .then((_) => ref.invalidate(recentSessionsProvider))
          .catchError((Object error) {
            debugPrint('recordCompletedSession failed: $error');
          }),
    );
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
    // 同步单一事实源:重连重申/进新房间时由 AblyRuntimeNotifier 读取。
    ref
        .read(ownActivityStatusProvider.notifier)
        .set(status.activityState == UserActivityState.idle ? null : status);
    // 广播到所有已订阅房间:同一个人同时在几个房间,运动状态处处一致
    // (事件流只发到打牌的那间;其余房间靠 presence 快照反哺折叠)。
    return ref.read(ablyRuntimeProvider.notifier).reassertPresence();
  }
}

final ownActionSessionProvider =
    NotifierProvider<OwnActionSessionNotifier, TemplateCardSession?>(
      OwnActionSessionNotifier.new,
    );

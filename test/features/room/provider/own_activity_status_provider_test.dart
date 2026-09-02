import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:cofit/features/room/provider/own_activity_status_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000);

  UserActivityStatusEntity activeStatus({
    required int updatedAtEpochMs,
    required int remainingSec,
  }) {
    return UserActivityStatusEntity(
      activityState: UserActivityState.active,
      actionKey: 'strength',
      durationSec: 60,
      remainingSec: remainingSec,
      sessionId: 'session-1',
      templateId: 'template-1',
      templateName: '深蹲',
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }

  group('reassertActivityStatusAt', () {
    test('active 未到点:刷新 remainingSec 与 updatedAtEpochMs,保留其余字段', () {
      // 30 秒前写入,剩 60 秒 → endsAt 在 30 秒后
      final status = activeStatus(
        updatedAtEpochMs: now.millisecondsSinceEpoch - 30_000,
        remainingSec: 60,
      );

      final refreshed = reassertActivityStatusAt(status, now);

      expect(refreshed.activityState, UserActivityState.active);
      expect(refreshed.updatedAtEpochMs, now.millisecondsSinceEpoch);
      expect(refreshed.remainingSec, 30);
      expect(refreshed.sessionId, 'session-1');
      expect(refreshed.templateName, '深蹲');
    });

    test('active 已到点:回 idle 并带新时间戳', () {
      final status = activeStatus(
        updatedAtEpochMs: now.millisecondsSinceEpoch - 90_000,
        remainingSec: 60,
      );

      final refreshed = reassertActivityStatusAt(status, now);

      expect(refreshed.activityState, UserActivityState.idle);
      expect(refreshed.updatedAtEpochMs, now.millisecondsSinceEpoch);
      expect(refreshed.sessionId, isNull);
    });

    test('active 缺 updatedAt/remaining:降级 idle', () {
      const status = UserActivityStatusEntity(
        activityState: UserActivityState.active,
        sessionId: 'session-1',
      );

      final refreshed = reassertActivityStatusAt(status, now);

      expect(refreshed.activityState, UserActivityState.idle);
      expect(refreshed.updatedAtEpochMs, now.millisecondsSinceEpoch);
    });

    test('idle:仅刷新时间戳(接收端严格更新检查需要新时间戳)', () {
      final status = UserActivityStatusEntity(
        activityState: UserActivityState.idle,
        updatedAtEpochMs: now.millisecondsSinceEpoch - 5_000,
      );

      final refreshed = reassertActivityStatusAt(status, now);

      expect(refreshed.activityState, UserActivityState.idle);
      expect(refreshed.updatedAtEpochMs, now.millisecondsSinceEpoch);
    });
  });
}

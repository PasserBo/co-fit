import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/ai_coach/usecase/build_coach_context_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

ActionSessionRecord _record(int i, DateTime at) => ActionSessionRecord(
  sessionId: 'session-$i',
  roomId: 'room-secret',
  userId: 'uid-secret',
  templateId: 'tpl-$i',
  templateName: '俯卧撑',
  actionKey: 'pushup',
  durationSec: 60 + i,
  startedAt: at.subtract(const Duration(minutes: 1)),
  completedAt: at,
);

void main() {
  const usecase = BuildCoachContextUsecase();
  final now = DateTime(2026, 11, 18, 21, 30);

  test('每条记录一行,只带时间/卡名/动作/时长,不带 id', () {
    final String context = usecase.execute([
      _record(1, DateTime(2026, 11, 18, 8, 5)),
    ], now: now);

    expect(context, contains('Today: 2026-11-18 (Wed)'));
    expect(context, contains('2026-11-18 08:05 | 俯卧撑 | pushup | 61'));
    expect(context, isNot(contains('uid-secret')));
    expect(context, isNot(contains('room-secret')));
    expect(context, isNot(contains('session-1')));
  });

  test('没有记录时明确告诉模型', () {
    expect(usecase.execute(const [], now: now), contains('(none'));
  });

  test('最多 100 条', () {
    final records = [
      for (var i = 0; i < 130; i++)
        _record(i, now.subtract(Duration(hours: i))),
    ];
    final int lines = usecase
        .execute(records, now: now)
        .split('\n')
        .where((l) => l.contains('| pushup |'))
        .length;
    expect(lines, BuildCoachContextUsecase.maxRecords);
  });
}

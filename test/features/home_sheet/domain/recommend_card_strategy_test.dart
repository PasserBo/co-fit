import 'package:cofit/features/action/domain/entity/action_session_record.dart';
import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_template_card.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/home_sheet/domain/recommend_card_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

ActionTemplateCard _card(String id) => ActionTemplateCard(
  id: id,
  name: id,
  type: ActionType.strength,
  rawType: 'strength',
  source: ActionSource.official,
  ablyActionId: id,
  defaultDurationSec: 60,
  intensityBaseline: const {},
);

ActionSessionRecord _done(String cardId, DateTime at) => ActionSessionRecord(
  sessionId: '$cardId-${at.millisecondsSinceEpoch}',
  roomId: 'r',
  userId: 'u',
  templateId: cardId,
  templateName: cardId,
  actionKey: 'strength',
  durationSec: 60,
  startedAt: at.subtract(const Duration(minutes: 1)),
  completedAt: at,
);

void main() {
  const strategy = LeastRecentlyDoneStrategy();
  final day = DateTime(2026, 11, 20);

  test('空手牌 → 没有可推荐的', () {
    expect(strategy.recommend(hand: const [], history: const []), isNull);
  });

  test('都没做过 → 手牌第一张', () {
    final hand = [_card('a'), _card('b')];
    expect(strategy.recommend(hand: hand, history: const [])?.id, 'a');
  });

  test('有没做过的 → 手牌顺序里第一张没做过的', () {
    final hand = [_card('a'), _card('b'), _card('c')];
    final history = [_done('a', day)];
    expect(strategy.recommend(hand: hand, history: history)?.id, 'b');
  });

  test('都做过 → 最久没做的那张(按每张卡最近一次完成时间)', () {
    final hand = [_card('a'), _card('b'), _card('c')];
    final history = [
      _done('a', day.subtract(const Duration(days: 5))),
      _done('a', day), // a 最近做过
      _done('b', day.subtract(const Duration(days: 3))),
      _done('c', day.subtract(const Duration(days: 1))),
    ];
    expect(strategy.recommend(hand: hand, history: history)?.id, 'b');
  });

  test('只推荐手牌里的卡:记录里其他卡不影响结果', () {
    final hand = [_card('a')];
    final history = [_done('z', day.subtract(const Duration(days: 30)))];
    expect(strategy.recommend(hand: hand, history: history)?.id, 'a');
  });
}

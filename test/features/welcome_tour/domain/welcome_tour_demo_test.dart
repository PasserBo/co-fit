// 演示数据与 SSOT 的一致性(design §3):改 `firestore/card_templates.json`
// 或 clip 库时,这里会先红。
import 'dart:convert';
import 'dart:io';

import 'package:cofit/features/avatar/presentation/renderer/motion_clip_library.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:cofit/features/welcome_tour/domain/entity/welcome_tour_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, Map<String, dynamic>> ssot;

  setUpAll(() {
    final raw = File('firestore/card_templates.json').readAsStringSync();
    final templates = (jsonDecode(raw) as Map<String, dynamic>)['templates'];
    ssot = {
      for (final t in templates as List)
        (t as Map<String, dynamic>)['id'] as String: t,
    };
  });

  test('demo cards match the card_templates SSOT field by field', () {
    expect(WelcomeTourDemo.cards.length, inInclusiveRange(3, 5));
    for (final card in WelcomeTourDemo.cards) {
      final doc = ssot[card.id];
      expect(doc, isNotNull, reason: '${card.id} 不在 SSOT 里');
      expect(card.name, doc!['name'], reason: card.id);
      expect(card.rawType, doc['type'], reason: card.id);
      expect(card.ablyActionId, doc['ablyActionId'], reason: card.id);
      expect(
        card.defaultDurationSec,
        doc['defaultDurationSec'],
        reason: card.id,
      );
      expect(card.motionId, doc['motionId'], reason: card.id);
      expect(card.order, doc['order'], reason: card.id);
      expect(
        card.intensityLabel,
        (doc['intensityBaseline'] as Map)['label'],
        reason: card.id,
      );
    }
  });

  test('every demo card has a real clip', () {
    for (final card in WelcomeTourDemo.cards) {
      expect(card.motionId, isNotNull, reason: card.id);
      expect(
        MotionClipLibrary.byId(card.motionId),
        isNotNull,
        reason: '${card.id} 的 clip ${card.motionId} 不在 clip 库',
      );
    }
  });

  test('sample members are 2–3 active, labelled 示例, with real clips', () {
    final members = WelcomeTourDemo.sampleMembers;
    expect(members.length, inInclusiveRange(2, 3));

    final demoCardMotions = {for (final c in WelcomeTourDemo.cards) c.motionId};
    final seenMotions = <String>{};
    for (final member in members) {
      expect(member.nickname, startsWith(WelcomeTourDemo.sampleNickname));
      expect(member.userId, isNot(WelcomeTourDemo.selfUserId));
      final status = member.activityStatus;
      expect(status.activityState, UserActivityState.active);
      expect(MotionClipLibrary.byId(status.motionId), isNotNull);
      expect(
        demoCardMotions.contains(status.motionId),
        isFalse,
        reason: '示例小人不该做演示手牌里的动作',
      );
      expect(seenMotions.add(status.motionId!), isTrue, reason: '动作应各不相同');
      // 动作名与 SSOT 一致(同一个 motionId 的卡)
      final doc = ssot.values.firstWhere(
        (d) => d['motionId'] == status.motionId,
      );
      expect(status.templateName, doc['name']);
      expect(status.actionKey, doc['type']);
    }
  });

  test('demo countdown is about ten seconds', () {
    expect(WelcomeTourDemo.sessionDurationSec, inInclusiveRange(8, 12));
  });
}

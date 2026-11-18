import '../../../action/domain/entity/action_source.dart';
import '../../../action/domain/entity/action_template_card.dart';
import '../../../action/domain/entity/action_type.dart';
import '../../../room/domain/entity/room_presence_member.dart';
import '../../../room/domain/entity/user_activity_status_entity.dart';

/// 登录前演示房间的固定数据(规格 `welcome-tour`,design §3)。
///
/// 全部是 Dart 常量,不读云端、不注册 asset:演示在登录前且可能离线。
/// 演示卡与 `firestore/card_templates.json` 的一致性由单测锁住
/// (`welcome_tour_demo_test.dart`),改 SSOT 时那条测试会红。
abstract final class WelcomeTourDemo {
  static const roomId = 'demo_room';
  static const selfUserId = 'demo_self';

  /// 演示里打出的卡一律按这个时长倒计时(决议 2026-11-13:约 10 秒)。
  static const sessionDurationSec = 10;

  /// 示例小人昵称前缀——规格要求「带示例标注、不是真人名字」。
  static const sampleNickname = '示例';

  /// 演示手牌:4 张有 clip 的官方卡(字段逐项对齐 SSOT)。
  static const cards = <ActionTemplateCard>[
    ActionTemplateCard(
      id: 'squat',
      name: '深蹲',
      type: ActionType.strength,
      rawType: 'strength',
      source: ActionSource.official,
      ablyActionId: 'squat',
      defaultDurationSec: 60,
      intensityBaseline: <String, dynamic>{'label': '中等'},
      motionId: 'squat',
      order: 10,
    ),
    ActionTemplateCard(
      id: 'jumping_jack',
      name: '开合跳',
      type: ActionType.cardio,
      rawType: 'cardio',
      source: ActionSource.official,
      ablyActionId: 'jumping_jack',
      defaultDurationSec: 45,
      intensityBaseline: <String, dynamic>{'label': '中等'},
      motionId: 'jumping_jack',
      order: 90,
    ),
    ActionTemplateCard(
      id: 'plank',
      name: '平板支撑',
      type: ActionType.core,
      rawType: 'core',
      source: ActionSource.official,
      ablyActionId: 'plank',
      defaultDurationSec: 45,
      intensityBaseline: <String, dynamic>{'label': '挑战'},
      motionId: 'plank',
      order: 170,
    ),
    ActionTemplateCard(
      id: 'pushup',
      name: '俯卧撑',
      type: ActionType.strength,
      rawType: 'strength',
      source: ActionSource.official,
      ablyActionId: 'pushup',
      defaultDurationSec: 45,
      intensityBaseline: <String, dynamic>{'label': '挑战'},
      motionId: 'pushup',
      order: 30,
    ),
  ];

  /// 3 个示例小人,各做一个**不在演示手牌里**的动作,
  /// 让用户打出的动作一定是新的。`remainingSec` 留空:场景只看
  /// state + motionId,气泡 chip 只显示动作名,不显示会走偏的剩余时间。
  static const sampleMembers = <RoomPresenceMember>[
    RoomPresenceMember(
      clientId: 'demo_sample_1',
      userId: 'demo_sample_1',
      nickname: '$sampleNickname A',
      activityStatus: UserActivityStatusEntity(
        activityState: UserActivityState.active,
        actionKey: 'cardio',
        templateName: '原地跑',
        motionId: 'run_in_place',
      ),
    ),
    RoomPresenceMember(
      clientId: 'demo_sample_2',
      userId: 'demo_sample_2',
      nickname: '$sampleNickname B',
      activityStatus: UserActivityStatusEntity(
        activityState: UserActivityState.active,
        actionKey: 'cardio',
        templateName: '高抬腿',
        motionId: 'high_knees',
      ),
    ),
    RoomPresenceMember(
      clientId: 'demo_sample_3',
      userId: 'demo_sample_3',
      nickname: '$sampleNickname C',
      activityStatus: UserActivityStatusEntity(
        activityState: UserActivityState.active,
        actionKey: 'core',
        templateName: '卷腹',
        motionId: 'crunch',
      ),
    ),
  ];
}

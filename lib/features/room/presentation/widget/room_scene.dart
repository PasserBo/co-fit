import 'package:flutter/material.dart';

import '../../../action/domain/entity/action_type.dart';
import '../../../avatar/presentation/renderer/avatar_renderer.dart';
import '../../domain/entity/room_presence_member.dart';
import '../../domain/entity/user_activity_status_entity.dart';
import 'avatar_bubble.dart';

/// 本地兜底:presence 里还没有自己(enter 回显未到 / 离线)时,
/// 用本地状态补一个自己,保证场景里永远能看到自己的小人。
/// presence 已含自己则原样返回。
List<RoomPresenceMember> withSelfPresent(
  List<RoomPresenceMember> members, {
  required String selfUserId,
  String? nickname,
  UserActivityStatusEntity? activityStatus,
}) {
  for (final member in members) {
    if (member.userId == selfUserId) {
      return members;
    }
  }
  return [
    ...members,
    RoomPresenceMember(
      clientId: 'local-$selfUserId',
      userId: selfUserId,
      nickname: nickname,
      activityStatus: activityStatus ?? UserActivityStatusEntity.idle(),
    ),
  ];
}

/// 在线 presence 与房间成员名单合并后的场景数据。
typedef RoomRoster = ({
  List<RoomPresenceMember> members,
  Set<String> offlineUserIds,
});

/// 把 Firestore 成员名单([rosterIds],有序)与在线 [online] 合并:
/// - 按名单顺序排列(锚点随人稳定,不因上下线跳位);同一 uid 多端在线只取一个;
/// - 名单里不在线的成员补 idle 占位(`offline-<uid>`),昵称取 [nicknames];
/// - 在线但不在名单里的(名单未加载 / 本地兜底的自己)追加在末尾。
RoomRoster withOfflineMembers(
  List<RoomPresenceMember> online, {
  required List<String> rosterIds,
  Map<String, String?> nicknames = const {},
}) {
  final onlineByUid = <String, RoomPresenceMember>{};
  for (final member in online) {
    onlineByUid.putIfAbsent(member.userId, () => member);
  }
  final members = <RoomPresenceMember>[];
  final offline = <String>{};
  final seen = <String>{};
  for (final uid in rosterIds) {
    if (!seen.add(uid)) {
      continue;
    }
    final present = onlineByUid[uid];
    if (present != null) {
      members.add(present);
    } else {
      offline.add(uid);
      members.add(
        RoomPresenceMember(
          clientId: 'offline-$uid',
          userId: uid,
          nickname: nicknames[uid],
        ),
      );
    }
  }
  for (final member in onlineByUid.values) {
    if (seen.add(member.userId)) {
      members.add(member);
    }
  }
  return (members: members, offlineUserIds: offline);
}

/// 漂浮气泡空间(#6b):好友小人散布在场景锚点上,自己固定在中下方。
/// 离线成员([offlineUserIds])以变暗的待机小人留在原锚点。
/// 纯展示:成员列表与动画渲染器由外部注入。
class RoomScene extends StatelessWidget {
  const RoomScene({
    required this.members,
    required this.selfUserId,
    required this.renderer,
    this.offlineUserIds = const {},
    this.showSelf = true,
    super.key,
  });

  final List<RoomPresenceMember> members;
  final String selfUserId;
  final AvatarRenderer renderer;
  final Set<String> offlineUserIds;

  /// false = 不画自己(房间主界面把自己的小人放在独立一层,见 add-home-sheet)。
  final bool showSelf;

  /// 好友锚点(FractionalOffset,取自 #6b/#t9 mock 的小人位置);
  /// 超出锚点数量的成员从头复用并轻微偏移。
  static const _anchors = [
    FractionalOffset(0.16, 0.16),
    FractionalOffset(0.66, 0.12),
    FractionalOffset(0.74, 0.44),
    FractionalOffset(0.24, 0.46),
    FractionalOffset(0.42, 0.24),
    FractionalOffset(0.85, 0.68),
    FractionalOffset(0.12, 0.70),
    FractionalOffset(0.55, 0.74),
  ];

  /// 自己在场景中的漂浮位置(房间主界面的独立小人层沿用它)。
  static const selfAnchor = FractionalOffset(0.5, 0.55);

  /// 优先 presence 昵称(G5 已接线 2026-08-10);无昵称回退 uid 前 6 位。
  static String displayName(RoomPresenceMember member) {
    final nickname = member.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    final id = member.userId.trim();
    return id.length <= 6 ? id : id.substring(0, 6);
  }

  static String? chipTextOf(RoomPresenceMember member) {
    final status = member.activityStatus;
    final name = status.templateName ?? status.actionKey;
    if (name == null) {
      return null;
    }
    final remaining = status.remainingSec;
    if (remaining == null || remaining <= 0) {
      return name;
    }
    final minutes = (remaining / 60).ceil();
    return '$name ${minutes}min';
  }

  /// 运动中的动作类型:actionKey = 卡片 rawType,经 fromRaw 归类。
  static ActionType? actionTypeOf(RoomPresenceMember member) {
    final key = member.activityStatus.actionKey;
    return key == null ? null : ActionType.fromRaw(key);
  }

  /// 固定相位偏移(README 帧同步规范第 5 条):hash(userId) 派生,
  /// 与启动时刻无关,避免全房间齐步走。
  static double phaseSeedOf(String userId) =>
      (userId.hashCode.abs() % 997) / 997;

  @override
  Widget build(BuildContext context) {
    final friends = members
        .where((m) => m.userId != selfUserId)
        .toList(growable: false);
    RoomPresenceMember? self;
    for (final member in members) {
      if (member.userId == selfUserId) {
        self = member;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < friends.length; i++)
              Align(
                alignment: _shiftedAnchor(i),
                child: offlineUserIds.contains(friends[i].userId)
                    ? AvatarBubble(
                        key: ValueKey(friends[i].clientId),
                        name: displayName(friends[i]),
                        state: UserActivityState.idle,
                        offline: true,
                        renderer: renderer,
                        phaseSeed: phaseSeedOf(friends[i].userId),
                      )
                    : AvatarBubble(
                        key: ValueKey(friends[i].clientId),
                        name: displayName(friends[i]),
                        state: friends[i].activityStatus.activityState,
                        actionType: actionTypeOf(friends[i]),
                        motionId: friends[i].activityStatus.motionId,
                        chipText: chipTextOf(friends[i]),
                        renderer: renderer,
                        phaseSeed: phaseSeedOf(friends[i].userId),
                      ),
              ),
            if (showSelf && self != null)
              Align(
                alignment: selfAnchor,
                child: AvatarBubble(
                  key: const ValueKey('self'),
                  name: '你',
                  state: self.activityStatus.activityState,
                  actionType: actionTypeOf(self),
                  motionId: self.activityStatus.motionId,
                  chipText: chipTextOf(self),
                  isSelf: true,
                  renderer: renderer,
                  phaseSeed: phaseSeedOf(self.userId),
                ),
              ),
          ],
        );
      },
    );
  }

  Alignment _shiftedAnchor(int index) {
    final anchor = _anchors[index % _anchors.length];
    final round = index ~/ _anchors.length;
    if (round == 0) {
      return anchor;
    }
    // 第 2 轮起向中心线性收缩
    final t = (round * 0.25).clamp(0.0, 0.75);
    return Alignment.lerp(anchor, Alignment.center, t)!;
  }
}

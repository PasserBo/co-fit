import 'package:flutter/material.dart';

import '../../domain/entity/room_presence_member.dart';
import 'avatar_bubble.dart';

/// 漂浮气泡空间(#6b):好友小人散布在场景锚点上,自己固定在中下方。
/// 纯展示:presence 列表由外部注入。
class RoomScene extends StatelessWidget {
  const RoomScene({
    required this.members,
    required this.selfUserId,
    super.key,
  });

  final List<RoomPresenceMember> members;
  final String selfUserId;

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

  static const _selfAnchor = FractionalOffset(0.5, 0.55);

  /// 昵称占位(G5 决议 2026-08-01):无昵称数据,截断 userId 前 6 位。
  static String displayName(RoomPresenceMember member) {
    final id = member.userId.trim();
    return id.length <= 6 ? id : id.substring(0, 6);
  }

  String? _chipText(RoomPresenceMember member) {
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

  @override
  Widget build(BuildContext context) {
    final friends =
        members.where((m) => m.userId != selfUserId).toList(growable: false);
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
                // 复用锚点时按轮次向中心收缩,避免完全重叠
                alignment: _shiftedAnchor(i),
                child: AvatarBubble(
                  key: ValueKey(friends[i].clientId),
                  name: displayName(friends[i]),
                  state: friends[i].activityStatus.activityState,
                  chipText: _chipText(friends[i]),
                ),
              ),
            if (self != null)
              Align(
                alignment: _selfAnchor,
                child: AvatarBubble(
                  key: const ValueKey('self'),
                  name: '你',
                  state: self.activityStatus.activityState,
                  chipText: _chipText(self),
                  isSelf: true,
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

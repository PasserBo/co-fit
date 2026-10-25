import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_info_entity.freezed.dart';

class RoomVisibility {
  static const String public = 'public';
  static const String unlisted = 'unlisted';
  static const Set<String> allowed = {public, unlisted};
}

@freezed
abstract class RoomInfoEntity with _$RoomInfoEntity {
  const RoomInfoEntity._();

  const factory RoomInfoEntity({
    required String roomId,
    required String name,
    required String description,
    required String visibility,
    required String ownerId,
    required String shareLinkHash,
    required String shareSalt,
    DateTime? createdAt,
    DateTime? updatedAt,

    /// 成员 uid 列表(含房主),由 Firestore `members` map 的 key 派生;
    /// 只读投影,不参与 [toMap] 写回(members 的写入走 repository 事务)。
    @Default(<String>[]) List<String> memberIds,

    /// true = 来自 Firestore 本地缓存的快照,**可能过期**(例如邀请预览时
    /// 缓存的旧文档,members 里还没有自己)。只能用于展示,
    /// 不得据此判定「被移出 / 已解散」——那会把自己误踢出房间。
    @Default(false) bool fromCache,
  }) = _RoomInfoEntity;

  /// 该用户是否仍是成员(被房主移出后为 false;房主恒为 true)。
  bool isMember(String userId) =>
      userId == ownerId || memberIds.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'description': description,
      'visibility': visibility,
      'ownerId': ownerId,
      'shareLinkHash': shareLinkHash,
      'shareSalt': shareSalt,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory RoomInfoEntity.fromMap(Map<String, dynamic> source) {
    return RoomInfoEntity(
      roomId: (source['roomId'] ?? '').toString(),
      name: (source['name'] ?? '').toString(),
      description: (source['description'] ?? '').toString(),
      visibility: (source['visibility'] ?? RoomVisibility.unlisted).toString(),
      ownerId: (source['ownerId'] ?? '').toString(),
      shareLinkHash: (source['shareLinkHash'] ?? '').toString(),
      shareSalt: (source['shareSalt'] ?? '').toString(),
      createdAt: _asDateTime(source['createdAt']),
      updatedAt: _asDateTime(source['updatedAt']),
      memberIds: _memberIdsOf(source['members']),
    );
  }

  static List<String> _memberIdsOf(Object? members) {
    if (members is! Map) {
      return const <String>[];
    }
    return [
      for (final key in members.keys)
        if (key.toString().trim().isNotEmpty) key.toString().trim(),
    ];
  }

  static DateTime? _asDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    final dynamic maybeDate = (value as dynamic).toDate?.call();
    if (maybeDate is DateTime) {
      return maybeDate.toLocal();
    }
    return null;
  }
}

import 'entity/invite_link_entity.dart';

/// 邀请链接格式(拼装与解析的单一事实源):
///   `cofit://room/<roomId>?h=<shareLinkHash>`
///
/// h 是「知道链接才能加入」的社交礼仪门槛,不是安全边界——
/// rules 层任何登录用户仍可对已知 roomId 自加入,本期接受。
abstract class InviteLinkFormat {
  static const scheme = 'cofit';
  static const host = 'room';
  static const hashParam = 'h';

  static Uri build({required String roomId, required String hash}) {
    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: [roomId],
      queryParameters: {hashParam: hash},
    );
  }

  /// 非邀请链接/字段缺失返回 null。
  static InviteLinkEntity? tryParse(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) {
      return null;
    }
    if (uri.pathSegments.length != 1) {
      return null;
    }
    final roomId = uri.pathSegments.first.trim();
    final hash = (uri.queryParameters[hashParam] ?? '').trim();
    if (roomId.isEmpty || hash.isEmpty) {
      return null;
    }
    return InviteLinkEntity(roomId: roomId, hash: hash);
  }
}

import 'package:app_links/app_links.dart';

import '../domain/entity/invite_link_entity.dart';
import '../domain/invite_link_format.dart';

/// 深链数据源:包装 app_links,输出解析后的邀请链接。
/// 非邀请格式的链接被静默丢弃。
class AppLinksDeepLinkSource {
  AppLinksDeepLinkSource({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// 冷启动链接(app 由链接拉起时);无则 null。
  Future<InviteLinkEntity?> getInitialInvite() async {
    final uri = await _appLinks.getInitialLink();
    if (uri == null) {
      return null;
    }
    return InviteLinkFormat.tryParse(uri);
  }

  /// 热启动链接流(app 已运行时点开链接)。
  Stream<InviteLinkEntity> watchInvites() {
    return _appLinks.uriLinkStream
        .map(InviteLinkFormat.tryParse)
        .where((invite) => invite != null)
        .cast<InviteLinkEntity>();
  }
}

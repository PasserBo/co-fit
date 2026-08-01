/// 卡片来源(G2 决议 2026-08-01)。
/// Firestore 文档暂无 `source` 字段,缺省一律视为 [official];
/// 自建/好友分享将在对应功能落地时开始写入该字段。
enum ActionSource {
  official,
  custom,
  friendShared;

  static ActionSource fromRaw(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'custom':
        return ActionSource.custom;
      case 'friendshared':
      case 'friend_shared':
        return ActionSource.friendShared;
      default:
        return ActionSource.official;
    }
  }
}

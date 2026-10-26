# CoFit 架构总览(2026-10-26 现状)

> 本文描述**已实现**的架构,是新成员/AI 助手理解代码的入口。
> 分层规则的权威文档仍是 [.cursor/rules/flutter_architecture.mdc](../.cursor/rules/flutter_architecture.mdc);
> 用户流程与页面完成度见 [flows_status.md](flows_status.md);UI 进度与决议见 [ui_overhaul/STATUS.md](ui_overhaul/STATUS.md)。
> 立项时的愿景稿(Rive 动画、等距街区、Live Activities 等)已随 git 历史保留,未实现的部分不再出现在本文。

## 1. 一句话

Flutter(iOS-only)App:好友以小人形式出现在共享「房间」里,打出一张动作卡牌就开始运动,其他人实时看到。
**Firestore 管"谁在哪个房间、有什么牌"(低频、持久),Ably 管"此刻谁在做什么"(高频、易失)。**

## 2. 技术栈

| 层 | 选型 | 备注 |
|---|---|---|
| UI | Flutter 3.41(fvm)+ Riverpod 3 | 深色唯一主题,设计 token 走 `cofit.tokens.json` → `CoFitColors`/`CoFitDimens` |
| 身份 | Firebase Auth | Apple / Google / 邮箱;Apple 与其他 provider 的 uid 不互通(待决议) |
| 持久数据 | Cloud Firestore | rules 显式声明每个集合,末尾全局 deny;rules 改动由 CI 部署 |
| 实时 | Ably Realtime | 每房间一个频道 `room:{roomId}:events`,presence + 事件两条通道 |
| 本地 | shared_preferences | 只存「进行中的运动会话快照」(被杀后恢复) |
| 动画 | 占位几何小人(`avatar`) | Rive 范围外;`AvatarRenderer` 接口留给将来替换 |

## 3. 目录与分层

```
lib/
├── main.dart                      # Firebase 初始化 + 启动错误边界 → AuthGatePage
├── core/
│   ├── navigation/                # AppShell(IndexedStack + 悬浮 dock,三槽位:房间/牌库/我的)
│   ├── theme/                     # token JSON、CoFitColors(ThemeExtension)、CoFitDimens、CoFitTheme
│   └── widget/                    # 跨 feature 纯 UI:FloatingDock、BrandSplash、CoFitConfirmSheet
├── firestore/                     # (历史命名)Ably 接入层:AblyService、AblyRuntimeNotifier
└── features/<name>/
    ├── domain/entity/             # @freezed 实体 + 派生规则(不依赖 Flutter/Firebase)
    ├── domain/*_repository.dart   # 仓库接口
    ├── data/                      # 仓库实现(Firebase / Ably / in-memory / shared_preferences)
    ├── usecase/                   # 一个文件一个用户动作
    ├── provider/                  # Riverpod 接线(DI),不算分层
    └── presentation/view|widget/  # view 读 provider;widget 纯展示
```

| feature | 职责 | 关键类型 |
|---|---|---|
| `auth` | 登录/登出、AuthGate 三态门控、「我的」页、登录后 bootstrap | `AuthGatePage`、`UserBootstrapNotifier` |
| `profile` | `users/{uid}` 资料、onboarding、账号删除 | `UserProfileEntity`、`DeleteAccountUsecase` |
| `room` | 房间 CRUD、成员管理、举报、presence/事件折叠、房间主界面 | `RoomInfoEntity`、`RoomBrowserNotifier`、`RoomActivitySnapshot` |
| `action` | 动作卡模板、自建卡、牌组、打牌会话、打卡历史、会话恢复 | `ActionTemplateCard`、`ActionDeck`、`OwnActionSessionNotifier` |
| `invite` | `cofit://room/<id>?h=<hash>` 深链解析与预览 | `InviteLinkFormat`、`InviteLinkGate` |
| `avatar` | 占位小人渲染与动作集 | `AvatarRenderer`、`IdleAvatarFigure` |
| `social` | **空目录**(好友系统 v2) | — |

## 4. 数据模型(Firestore)

| 路径 | 内容 | 读 | 写 |
|---|---|---|---|
| `rooms/{roomId}` | name/description/visibility/ownerId/shareLinkHash/shareSalt/**members{uid: {userId, role, joinedAt}}** | 登录用户 | owner 全量编辑(含移出成员);成员只能加入/移除自己 |
| `users/{uid}` | nickname/avatarConfig/`activeDeckId` | 登录用户(昵称要被同房间人读) | 本人 |
| `users/{uid}/memberships/{roomId}` | 已加入房间索引 | 本人 | 本人 |
| `users/{uid}/decks/{deckId}` | 牌组 `{name, cardTemplateIds[]}` | 本人 | 本人 |
| `users/{uid}/cards/{cardId}` | 自建卡 | 本人 | 本人 |
| `users/{uid}/sessions/{sessionId}` | 打卡日志(只追加) | 本人 | 本人 create/delete,禁 update |
| `card_templates/{id}` | 官方卡 | 登录用户 | 禁 |
| `reports/{id}` | 举报 `{reporterId, roomId, targetUserId?, reason, createdAt}` | 禁 | 本人 create |

客户端派生字段:`RoomInfoEntity.memberIds`(members 的 key)、`RoomInfoEntity.fromCache`(快照来源),均不写回。

## 5. 实时模型(Ably)

```
room:{roomId}:events
├── presence  data = {userId, nickname, activity: UserActivityStatusEntity.toMap()}
│             enter 整包写,update 整包替换(无 merge)
└── messages  RoomEvent{eventId, roomId, userId, type, timestamp, payload}
              type ∈ action_started / paused / resumed / completed
```

**两条通道输出同一形状**(`UserActivityStatusEntity`),接收端不区分来源:

- 事件流 → `RoomActivitySnapshot.apply()` 折叠成「每用户当前会话」(`ActionSession`,用 `endsAt` 时间点建模,剩余秒数随 now 派生,本地到点即回待机);
- presence 快照 → `applyPresenceStatus()` 反哺折叠(晚进房者的唯一来源;时间戳不新于已有会话的会被丢弃);
- `RoomMainView._mergedMembers` = presence 成员 ∪ 本地自己(`withSelfPresent`) ⊕ 会话状态覆盖。

自己的状态单一事实源是 `ownActivityStatusProvider`(room feature);
`AblyRuntimeNotifier.reassertPresence()` 把它**广播到所有已订阅房间**(打牌、完成、回前台、进新房间时)。

## 6. 关键生命周期

```
启动 ─► AuthGate(authState → profile 三态)
        └► UserBootstrapNotifier.bootstrap(uid)
             ① Ably initializeForUser   ② fetchJoinedRoomIds   ③ 逐房间 subscribeRoom(enter presence 带 activity)
             ④ RoomBrowserNotifier.syncJoinedRooms(订阅事件/presence 流)
             ⑤ OwnActionSessionNotifier.recoverPending(补记过期会话 / 恢复倒计时)

打牌 ─► play(): 发布 action_started → 本地计时 → 写 PendingSessionSnapshot → reassertPresence(全房间)
到点 ─► complete(): 发布 action_completed → 清快照 → 落 sessions 记录 → presence 回 idle

被移出/解散 ─► roomInfoProvider(Firestore 快照流)收到服务端帧
              → RoomMainView._watchGoneRooms(所有已加入房间)→ toast + cleanupRemovedRoom
                (leaveRoom 容忍自己已不在 members / 房间已删除 → Ably leave → 刷新列表)
```

## 7. 不变量与踩过的坑(改代码前先读)

1. **Firestore `snapshots()` 第一帧可能来自缓存。** 任何「据此做破坏性动作」(退出房间、删 membership)的判定必须只认服务端帧——`RoomInfoEntity.fromCache == true` 时一律不算数。2026-10-26 曾因此把刚加入的用户自己踢出房间。
2. **Ably presence 必须先 `subscribe()` 再 `get()`**(`AblyService.watchPresence`),否则自己 enter 的回显会丢且无人再触发。
3. **presence update 是整包替换**,`userId` 键永远要带,否则读侧退化成 clientId。
4. **接收端对 presence 快照做严格时间戳检查**:重申 presence 必须刷新 `updatedAtEpochMs`(`reassertActivityStatusAt`),否则被静默丢弃。
5. **rules 第三分支只允许成员移除自己且要求自己仍在 members 里**:被房主移出后 `leaveRoom` 只能删 membership,不能再 update 房间文档。
6. **账号删除顺序**:先清 Firestore,再注销 Auth(uid 失效后 rules 拒绝一切写入)。
7. **Apple 登录凭证必须带 `authorizationCode`**,否则 Firebase 报 `Invalid OAuth response from apple.com`(文案误导)。
8. **UI 禁止裸 hex / magic number**;新数值先进 token JSON 再进 Dart。
9. `dart format` 只跑在自己改的文件上——仓库历史文件未全量格式化,整目录 format 会产生大量无关 diff。

## 8. 上架前仍缺(非代码)

隐私政策 + 用户协议 URL(需域名,顺带可托管 AASA 做 Universal Links)、`PrivacyInfo.xcprivacy`、正式 App 图标(现为临时版)、App Store Connect 演示账号与截图、Release 构建传 `--dart-define-from-file=.env` 的脚本化。

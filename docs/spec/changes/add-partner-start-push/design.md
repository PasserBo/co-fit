# Design: add-partner-start-push

CoFit 第一次引入服务端代码(Cloud Functions)和远程推送(FCM → APNs)。

## 1. 数据流

```
开始一张卡(StartTemplateCardActionUsecase 之后)
  ├─ Ably: action_started(照旧)
  └─ Firestore: users/{uid}/workout_starts/{sessionId}   ← 新,失败只记日志,不影响运动
        │ onDocumentCreated (us-central1,与数据库 nam5 同区)
        ▼
  functions/ partnerStartPush
    1. 过期检查:createdAt − startedAt > 10 分钟 → 丢弃
    2. 发起人的房间:users/{sender}/memberships → rooms/{id}.members
    3. 对每个接收者(≠ 发起人,跨房间去重):
         settings/notifications.partnerStartEnabled == false → 跳过
         共同房间 − mutedRoomIds 为空 → 跳过
         选房间:出牌房间(若在可选集合内)否则可选集合第一个(按房间名排序)
         事务:notification_state/partner_start.lastSentAt 在冷却内 → 跳过;否则写 now
         devices/* 的 token → sendEach;注销失效的 token
    4. finally 删除这条 workout_starts(不留存)
```

## 2. Firestore 数据(都在 `users/{uid}` 下,账号删除需清理)

| 路径 | 字段 | 客户端权限 |
|---|---|---|
| `devices/{token}` | `token`, `platform`('ios'), `updatedAt` | 本人 create/update/delete,不可读他人 |
| `settings/notifications` | `partnerStartEnabled?: bool`, `mutedRoomIds?: list<string>`(≤ 200), `updatedAt` | 本人读写删;文档不存在 = 开、无静音 |
| `workout_starts/{sessionId}` | `roomId`, `startedAt`(客户端时间), `createdAt == request.time` | 本人 create(roomId 必须有本人 membership)/ delete;不可读改 |
| `notification_state/{kind}` | `lastSentAt` | 本人读 / 删;**只有服务端写** |

- 设备文档 id 直接用 FCM token(天然去重;token 刷新时删旧写新)。
- 静音存成设置文档里的房间 id 列表,不改 membership 的 shape(membership 的更新规则很紧,牵连房间同步)。退房后残留的 id 无害。
- `FirebaseUserDataEraser._subcollections` 增加 `devices`, `settings`, `workout_starts`, `notification_state`。

## 3. 服务端(`functions/`,TypeScript,Node 22,firebase-functions v2)

- 纯逻辑(选接收者、选房间、冷却判断、文案替换)放 `src/partner_start/logic.ts`,单测不依赖模拟器;Firestore / Messaging 访问放薄的 `handler.ts`。
- **配置是内容**:Remote Config 服务端模板参数 `partner_start_push_config`(JSON 字符串):
  `{"cooldownHours": 3, "staleMinutes": 10, "title": "{room}", "body": "你的「{room}」运动伙伴 {nickname} 开始运动了!"}`。
  参数缺失或解析失败用代码内默认值(同上)。占位符:`{room}`、`{nickname}`。
- 推送载荷:`notification{title, body}` + `data{type: 'partner_start', roomId}`,APNs `sound: default`,`thread-id: roomId`(同房间的通知在通知中心归成一组)。
- 失效 token:`messaging/registration-token-not-registered`、`messaging/invalid-registration-token` → 删除对应 `devices` 文档。

## 4. 客户端(`lib/features/notification/`)

- `domain/`:`NotificationSettings` entity(enabled、mutedRoomIds);`PushTokenRepository`、`NotificationSettingsRepository`、`WorkoutStartSignalRepository` 接口;`PushPermissionGateway`(系统权限状态 / 请求 / 是否已请求过)。
- `usecase/`:登记 token(登录后、token 刷新时)、注销 token(退出登录前)、写开始信号、切换总开关、切换房间静音、`ShouldAskPushPermission`(纯函数:未请求过 && 房间里有其他成员)。
- `infrastructure` 照惯例放 `data/`:Firebase 实现。
- 前台:`FirebaseMessaging.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false)`。
- 点开:`getInitialMessage()` + `onMessageOpenedApp` → `data.roomId` → 若是本人房间则切到该房间(复用房间切换的现有入口),否则忽略。
- 「只主动请求一次」不另存标记:系统权限状态离开 notDetermined 就不再问。
- 设备同步:权限 notDetermined → 什么都不做;authorized → 登记;denied → 撤登记。
- 退出登录:`SignOutUsecase` 的 beforeSignOut 钩子(5 秒超时,失败不阻止退出)撤登记 + `deleteToken()`。

## 5. iOS

- `Runner.entitlements` 增加 `aps-environment`(development;Archive 时由签名换成 production)。
- `firebase_messaging` 16.x 走 SPM(与其他 FlutterFire 插件一致)。
- `aps-environment` 加上后,App ID 没开 Push Notifications 之前真机 / Archive 签名会失败。
- 需要 Apple Developer 后台给 `com.passerbo.cofitapp` 打开 Push Notifications,并把 APNs Auth Key(.p8)上传到 Firebase console(me)。

## 6. 部署

- `firebase.json` 增加 `functions`(source `functions`,predeploy `npm run build`)。
- 新 workflow `deploy-functions.yml`:push 到 main 且 `functions/**` 有改动时,`npm ci` → build → `npm test`(纯逻辑)→ `npm run test:emu`(Firestore 模拟器:rules + handler 集成)→ `firebase deploy --only functions --force`。复用 rules 部署的 service account,需要额外角色(tasks T19)。
- 本地测试:`cd functions && npm test`;`npm run test:emu`(需要 Java)。
- rules 改动走现有 `deploy-rules.yml`,推送前给用户看 diff。

## 7. 风险与取舍

- 开始信号写 Firestore 是一次额外写入(每张卡一次),写完即删,成本可忽略。
- 冷却在接收者一侧,所以一个很活跃的房间不会让任何人一天收到超过 24/N 条。
- 服务端读发起人所有房间的成员:房间数和成员数都小,不做分页。
- 隐私:推送内容(房间名、昵称)经 Google / Apple 传到对方设备;PrivacyInfo、ASC App Privacy、隐私政策需同步检查(me)。

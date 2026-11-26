# Tasks: add-partner-start-push

## Now
2026-11-26:代码已提交推送 main;Blaze、App ID 推送能力、APNs key(Key ID `VG4U48LNDU`,dev + prod 都已上传到 `com.passerbo.cofitapp`)完成;`partnerStartPush` 已从本机部署上线(Node 22,us-central1);rules 由 CI 部署。下一步:T21 真机双账号走查(me)。CI 的 Functions 部署权限(T19 方案 B)可以以后再补,在那之前改 `functions/` 在本机部署。
⚠️ App 带 `aps-environment` entitlement:App ID 已开推送,真机签名应当正常;若 Xcode / build_ipa 报 profile 不含推送能力,让签名重新生成 profile 即可。

## M1 · 服务端与数据
- [x] T1 `firestore.rules`:新增 `devices` / `settings` / `workout_starts` / `notification_state` 四段 — owner: agent · done 2026-11-26
  - evidence: `functions/test/rules.emu.test.ts` 12 项(`npm run test:emu`,Firestore 模拟器)
- [x] T2 用户确认 T1 的 diff(`git diff firestore.rules`)— owner: me · after: T1 · done 2026-11-26
  - evidence: 用户在对话中回复「改动OK」
- [x] T3 `functions/` 项目骨架(TS、Node 22(Node 20 已于 2026-10-30 停用)、firebase-functions v6 / v2 API、jest)+ `firebase.json` 的 functions / emulators — owner: agent · done 2026-11-26
  - evidence: `npm run build` 通过
- [x] T4 纯逻辑 `src/partner_start/logic.ts` — owner: agent · done 2026-11-26
  - evidence: `test/logic.test.ts` 18 项(配置解析、过期、去重、选房间、冷却、设置解析、文案)
- [x] T5 `handler.ts` + `index.ts`(触发器、Remote Config 模板、sendEach、清失效 token、finally 删信号)— owner: agent · done 2026-11-26
  - evidence: `test/handler.emu.test.ts` 7 项(真模拟器 + 假 Messaging):各收一条 / 发起人不收 / 两房间只一条 / 离线信号 / 冷却 / 总开关 / 全静音 / 换房间 / 无设备不占冷却 / 失效 token 删除
- [x] T6 `.github/workflows/deploy-functions.yml`(push main 且 `functions/**` 改动 → build + 单测 + 模拟器测试 → deploy)— owner: agent · done 2026-11-26
  - evidence: 读过一遍;未实际运行(要等 T16、T19)

## M2 · 客户端
- [x] T7 加 `firebase_messaging` 16.x,`Runner.entitlements` 加 `aps-environment` — owner: agent · done 2026-11-26
  - evidence: `pod install`(3 依赖 / 6 pod,正常)+ `flutter build ios --simulator` 通过,模拟器启动正常、已登录账号进房间
- [x] T8 `lib/features/notification/`:entity、repository 接口与 Firebase 实现、usecase、provider — owner: agent · done 2026-11-26
  - evidence: `test/features/notification/notification_usecase_test.dart` 24 项
- [x] T9 进入 App / 回到前台 / token 刷新时同步登记;退出登录前撤登记并作废 token — owner: agent · done 2026-11-26
  - evidence: `SyncPushDeviceUsecase`、`UnregisterPushDeviceUsecase`、`SignOutUsecase` 钩子(失败 / 超时不阻止退出)单测;`PushLifecycleBinder` 包在 AppShell 外
  - 注:模拟器日志 `push: device sync failed permission-denied` 是 rules 未部署所致,部署后消失
- [x] T10 开始一张卡时写开始信号(失败只记日志)— owner: agent · done 2026-11-26
  - evidence: `OwnActionSessionNotifier.play` → `_signalStart`;全量测试 435 过
- [x] T11 前台不弹(main 里设置);点开推送切换到房间(冷启动 + 后台),不在该房间则忽略 — owner: agent · done 2026-11-26
  - evidence: `PushMessage.partnerStartRoomId` 单测;真机点开待 T21
- [x] T12 账号删除清理列表增加四个子集合 — owner: agent · done 2026-11-26
  - evidence: `FirebaseUserDataEraser._subcollections`

## M3 · 设置与权限
- [x] T13 「我的」→「通知」分组:伙伴开始运动时通知我(开关);系统权限被拒时多一行「系统通知已关闭 · 去设置」 — owner: agent · done 2026-11-26
  - evidence: `my_page_body_test.dart` 4 项;未在模拟器上目视(点模拟器需要用户授权设备访问)
- [x] T14 房间菜单「静音通知 / 取消静音」(房主与成员都有),操作后 SnackBar — owner: agent · done 2026-11-26
  - evidence: `room_actions_sheet_test.dart` 4 项
- [x] T15 和伙伴同房间完成一张卡后请求权限(系统只弹一次)— owner: agent · done 2026-11-26
  - evidence: `shouldAskPushPermission` / `AskPushPermissionAfterWorkoutUsecase` 单测

## M4 · 外部配置与上线(me)

建议顺序:T16 → T17 → T18 → T2 → 提交推送 main(T19 的 CI 部署随之触发)→ T21。

- [x] T16 Firebase 升级 Blaze:console → ⚙️ → 使用情况和结算 → 修改方案 → Blaze;建议在 Google Cloud Billing 设一个预算提醒(例:¥1000/月)— owner: me · done 2026-11-26
  - evidence: Functions 部署成功(需要 Blaze)
- [x] T17 Apple Developer(团队 J95TRWHWYM):
  1. Identifiers → `com.passerbo.cofitapp` → 勾选 **Push Notifications** → Save;
  2. Keys → ➕ → 勾选 **Apple Push Notifications service (APNs)**(环境选 Sandbox & Production)→ 下载 `.p8` 放到 `keys/`(已 gitignore),记下 Key ID。
  — owner: me · done 2026-11-26
  - evidence: Key ID `VG4U48LNDU`,`.p8` 在 `keys/`
- [x] T18 Firebase console → ⚙️ 项目设置 → Cloud Messaging → Apple 应用配置 → APNs 身份验证密钥 → 上传 T17 的 `.p8`,填 Key ID 与团队 ID `J95TRWHWYM` — owner: me · after: T17 · done 2026-11-26
  - evidence: 用户上传到 `com.passerbo.cofitapp` 的 development 与 production 两行(旧 app `com.passerbo.cofit` 未使用)
- [ ] T19 Functions 首次部署(**A 已完成 2026-11-26**:本机部署成功,首次因 Eventarc 服务账号权限传播等待后重试;Node 20 已停用,改用 Node 22;B 待做)。二选一:
  - A(推荐,最省事)本机用你自己的 owner 账号部署一次,会自动开启所需 API:
    `cd functions && NODENV_VERSION=20.12.0 npm ci && cd .. && NODENV_VERSION=20.12.0 firebase deploy --only functions --project cofit-lmdyd`
    之后的改动走 CI;CI 的 service account(secret `FIREBASE_SERVICE_ACCOUNT`)仍需要下面 B 的角色。
  - B 只走 CI:在 Google Cloud IAM 给该 service account 加 Cloud Functions Admin、Cloud Run Admin、Service Account User、Artifact Registry Administrator、Cloud Build Editor、Eventarc Admin;推送 main 后看 `gh run list --workflow=deploy-functions.yml`,失败时按报错补角色 / 开 API。
  — owner: me · after: T16 · verify: Functions 列表里有 `partnerStartPush`(us-central1)
- [ ] T20 隐私:推送内容(房间名、昵称)经 Apple / Google 送到对方设备;检查隐私政策是否需要一句说明,PrivacyInfo / ASC App Privacy 是否需要调整 — owner: me · verify: 用户确认
- [ ] T21 真机双账号走查(两台设备同一房间):A 开始一张卡 → B 收到推送;3 小时内 A 再开始 → B 不收;B 静音房间 / 关总开关 → 不收;B 点开推送 → 进房间;B 退出登录 → 不收;前台不弹 — owner: me · after: T2, T16–T19 · verify: 用户确认
- 可选:Remote Config 新建字符串参数 `partner_start_push_config`(JSON:`cooldownHours` / `staleMinutes` / `title` / `body` / `fallbackNickname`)改冷却和文案;不建就用内置默认值(3 小时、「你的「{room}」运动伙伴 {nickname} 开始运动了!」)。

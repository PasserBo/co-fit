# Design: add-pre-signup-onboarding

> 行为以 [specs/welcome-tour/spec.md](specs/welcome-tour/spec.md) 为准,本文只讲怎么搭。代码事实基于 main @ ce51591(2026-11-13)。

## 1. 放在哪、怎么接到门控

新 feature 目录 `lib/features/welcome_tour/`,按 `.cursor/rules/flutter_architecture.mdc` 分层:

```
welcome_tour/
├── domain/
│   ├── entity/welcome_tour_demo.dart        演示数据(示例成员、演示手牌、缩短时长)— 纯常量 + 纯函数
│   └── welcome_tour_seen_repository.dart    接口:Future<bool> isSeen() / Future<void> markSeen()
├── data/
│   ├── shared_preferences_welcome_tour_seen_repository.dart   键 cofit.welcome_tour_seen.v1
│   └── in_memory_welcome_tour_seen_repository.dart            测试用
├── provider/welcome_tour_providers.dart     repository DI + welcomeTourSeenProvider(AsyncNotifier<bool>)
└── presentation/
    ├── view/welcome_tour_view.dart          页面:读 provider、持有演示会话与引导步骤
    └── widget/
        ├── tour_hint_bubble.dart            单条引导文案(纯展示)
        └── tour_finish_card.dart            收尾文案 + 「登录」主按钮(纯展示)
```

门控改动只在 [auth_gate_page.dart](../../../../lib/features/auth/presentation/auth_gate_page.dart) 的 `user == null` 分支:

```
user == null
  ├─ pendingInviteProvider != null        → markSeen(fire-and-forget) + LoginPageView
  ├─ welcomeTourSeenProvider loading      → BrandSplash(防闪:不能先闪登录页再切演示)
  ├─ seen == false                        → WelcomeTourView
  └─ seen == true                         → LoginPageView(现状)
```

`WelcomeTourView` 自己不做导航:跳过 / 点「登录」都只调用 `markSeen()`,`welcomeTourSeenProvider` 变为 true 后 AuthGate 的 `AnimatedSwitcher` 自然切到登录页(与现状「profile 流出新值即切主壳」同一套路)。登录页不加返回按钮,符合提案「不改登录页」。

「曾经登录过又退出」不出现演示:`markSeen()` 在用户成功登录后也写一次(AuthGate 进入 `_buildLoggedIn` 时 fire-and-forget),这样退出登录回到 `user == null` 分支时 seen 已为 true。老用户升级到这个版本时同理——第一次进 `_buildLoggedIn` 就打标,不会在他们退出后突然看到演示。

邀请链接的两个场景(冷启动带链接 / 演示中链接到达)都靠 AuthGate `ref.watch(pendingInviteProvider)` 覆盖:链接一到,分支切到登录页并打标;`InviteLinkGate` 在登录后照常消费,不动。

## 2. 演示房间怎么复用正式房间

| 正式房间 | 演示房间 | 说明 |
|---|---|---|
| `RoomScene(members, selfUserId, renderer)` | 同一个 widget | 纯展示,喂 `List<RoomPresenceMember>` 即可 |
| `withSelfPresent(...)`(room_scene.dart) | 同一个函数 | 自己的小人由本地兜底必然在场 |
| `CardFan(cards, focused, onPlay…)` | 同一个 widget | 纯展示 |
| `_ActivityHud`(room_main_view.dart 私有) | **抽成** `room/presentation/widget/activity_hud.dart` | 小重构,行为不变;演示与正式共用 |
| `OwnActionSessionNotifier` | **不用**。演示用 `WelcomeTourView` 内部的本地会话 | 它会写 presence、pending 快照、历史,全是演示不能留的痕迹 |
| 1 秒 ticker 驱动 `DateTime.now()` 重建 | 同一套路 | `ActionSession` 以 `endsAt` 表示进行中,剩余时间是派生值 |

本地演示会话:`WelcomeTourView` 的 state 持有一个 `ActionSession?`(复用 room 的 entity,`roomId: 'demo'`)。打牌 → 构造 `ActionSession(status: active, durationSec: 10, endsAt: now + 10s, motionId: card.motionId …)`;ticker 每秒 `setState`;`isExpiredAt(now)` 为真 → 置 completed 并显示收尾卡。自己的 `RoomPresenceMember.activityStatus` 直接用 `session.toActivityStatus(now)`,所以 `RoomScene` 与 `ActivityHud` 收到的形状与正式房间完全一样,动作、光圈、完成动画都是现成的。运动中再次打牌:`session != null && !isExpiredAt` 时忽略 `onPlay`(与正式房间 `_isPlaying` 守卫一致)。

## 3. 演示数据(SSOT 与校验)

**演示手牌**:Dart 常量,4 张,全部是有 clip 的官方卡:`squat`(深蹲)、`jumping_jack`(开合跳)、`plank`(平板支撑)、`pushup`(俯卧撑)。不读云端、不注册 asset。
防漂移:单测读取仓库里的 `firestore/card_templates.json`,断言每张演示卡的 `id / name / type / motionId` 与 SSOT 一致。改 SSOT 时这条测试会红。

**示例小人**:3 个 `RoomPresenceMember`,`userId` 为 `demo_1..3`,`nickname` 为「示例 A / 示例 B / 示例 C」(满足「带示例标注、不是真人名字」,不新增 UI 元素),`activityStatus` 固定 active,`motionId` 各不相同:`run_in_place`、`high_knees`、`crunch`(避开演示手牌里的四个,让用户打出的动作一定是新的)。`remainingSec` 给一个很大的常量,ticker 不去减它——`RoomScene` 只看 state + motionId,不看倒计时。

`phaseSeed` 由 `RoomScene` 按 userId hash 自动错相,不用管。

## 4. 引导文案与收尾

三步引导是 `WelcomeTourView` 的一个枚举 state(`self → play → friends → done`):

| 步骤 | 触发进入 | 文案意思 | 定位 |
|---|---|---|---|
| self | 进入演示 | 这个发光的小人就是你 | 自己小人上方 |
| play | 点引导或场景任意处 | 上滑中间那张卡,开始运动 | 手牌上方 |
| friends | 第一张卡打出 | 好友会以小人形式出现在同一房间,实时看到彼此在练什么 | 示例小人旁 |
| done | 第一张卡倒计时结束 | 收尾卡:登录后把好友叫进来 | 居中,不遮手牌 |

引导气泡是纯展示 overlay,`IgnorePointer` 包住,**不拦截**手牌手势;用户直接上滑打牌时步骤从 self 直接跳到 friends。倒计时缩短的说明放在 HUD 下方一行小字(「演示已缩短,正式房间按卡面时长」),只在 session active 时显示。

收尾卡出现后手牌仍可用(规格「仍可继续打牌」);再次完成不重复弹收尾卡,它一直停在那里。

右上角「跳过」是文字按钮(与 #19a 登录页次级文字链同风格),位置避开 `RoomTopBar` 的房名区——演示不用 `RoomTopBar`,顶栏只放「演示房间」小标 + 「跳过」。

## 5. 设计 token / 文案

- 优先复用现有 token(`bgSurface`、`borderSubtle`、`primaryMain @16%` 淡底等)。引导气泡若需要新的圆角/间距数值,走 `design-tokens` skill 先进 `cofit.tokens.json`。
- 文案与全 App 一致:中文内联,不建 string catalog。
- 实现前先过 `ui-implementation` skill;演示房间没有专门设计稿,按 #6b 主界面 + #19a 登录页的语言做,引导气泡按 stub 协议登记到 `docs/ui_overhaul/STATUS.md`。

## 6. 权衡与放弃的方案

- **不用 Remote Config 开关。** 演示在登录前、可能离线,远端开关在首启拿不到值,只能靠默认值,等于没有。真要紧急关掉就发版。
- **不把 `firestore/card_templates.json` 注册为 asset。** 省去 asset 管线与运行时解析,靠单测锁定一致性;演示只需 4 张。
- **不复用 `OwnActionSessionNotifier` 加一个 `dryRun` 参数。** 那条路径耦合 Ably/pending/history 三件事,加旗标会让正式路径多出一堆 `if`;本地 40 行会话更清楚。
- **「已看过」标记不随账号同步。** 它是设备级的首启体验,重装再看一次是可接受的(规格已写明)。
- **跳过/登录不做二次确认。** 演示没有任何可丢失的东西。

## 7. 风险

- `_ActivityHud` 抽出时要保持 `room_main_view.dart` 行为不变,靠现有 `room_scene_test` 与手动跑一次正式房间确认。
- AuthGate 多一个异步分支(seen 加载),首启会多一帧 splash;`SharedPreferences` 读取是毫秒级,可接受。
- App Review:示例小人昵称含「示例」且不可交互,避免被认为伪造真实用户;演示不收集任何数据,无需改 `PrivacyInfo.xcprivacy`。

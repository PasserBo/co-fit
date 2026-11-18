# Design: welcome-tour

> 行为以 [spec.md](spec.md) 为准,本文只讲现在怎么搭。来源:change `add-pre-signup-onboarding`(已归档,main @ d30242b,2026-11-18)。

## 1. 目录与门控

```
lib/features/welcome_tour/
├── domain/
│   ├── entity/welcome_tour_demo.dart        演示数据:示例成员、演示手牌、缩短时长(纯常量)
│   └── welcome_tour_seen_repository.dart    接口:isSeen() / markSeen()
├── data/
│   ├── shared_preferences_welcome_tour_seen_repository.dart   键 cofit.welcome_tour_seen.v1
│   └── in_memory_welcome_tour_seen_repository.dart            测试用
├── provider/welcome_tour_providers.dart     repository DI + welcomeTourSeenProvider(AsyncNotifier<bool>)
└── presentation/
    ├── view/welcome_tour_view.dart          页面:本地演示会话、引导步骤、收尾卡
    └── widget/tour_hint_bubble.dart · tour_finish_card.dart   纯展示
```

未登录分支的取舍是纯函数 `resolveUnauthenticatedStage`(`auth/presentation/unauthenticated_stage.dart`),AuthGate 只负责喂值和切页:

```
user == null
  ├─ 有滞留的邀请链接        → 登录页,并打「已看过」标(post-frame,幂等)
  ├─ 已看过读取失败          → 登录页(宁可少看演示,不卡住登录)
  ├─ 已看过尚未读出          → BrandSplash(防止先闪登录页再切演示)
  ├─ 未看过                  → WelcomeTourView
  └─ 已看过                  → 登录页
```

- `WelcomeTourView` 不做导航:「跳过」和收尾卡的「登录」都只调 `markSeen()`;provider 变 true 后 AuthGate 的 `AnimatedSwitcher` 切到登录页。
- 登录后第一次进入 `_buildLoggedIn` 也打标,所以退出登录、老用户升级后退出,都不会再看到演示。
- 「已看过」是设备级的,不随账号同步;删 App 重装会再看一次。

## 2. 复用正式房间

| 正式房间 | 演示房间 |
|---|---|
| `RoomScene` + `withSelfPresent` | 同一套,喂本地成员 |
| `CardFan` | 同一个 widget |
| `ActivityHud`(`room/presentation/widget/activity_hud.dart`) | 共用 |
| `OwnActionSessionNotifier` | **不用**:它写 presence、pending 快照、运动历史 |

本地会话:`WelcomeTourView` 持有 `ActionSession?`,打牌时构造 `status: active, durationSec: 10, endsAt: now + 10s`;1 秒 `Timer.periodic` 检查 `isExpiredAt(now)`,到点清空会话并进入收尾。时钟可注入(`now` 参数),测试用假钟推进。运动中再次打牌直接忽略。

## 3. 演示数据与防漂移

- 手牌 4 张官方卡:深蹲、开合跳、平板支撑、俯卧撑。字段与 `firestore/card_templates.json` 逐项一致,由 `welcome_tour_demo_test.dart` 读仓库文件断言;改 SSOT 或 clip 库时这条测试先红。
- 示例小人 3 个,`userId` 为 `demo_sample_1..3`,昵称「示例 A/B/C」,固定 active,动作原地跑 / 高抬腿 / 卷腹,与手牌动作不重叠;`remainingSec` 为 null,场景只看状态和 motionId。
- 演示不读云端、不注册 asset,离线可完整走通。页面测试的 ProviderScope 只覆盖「已看过」仓库,碰到任何 Firebase / Ably provider 都会报错,这是离线运行的回归保护。

## 4. 引导与收尾

- 步骤枚举 `self → play → friends → done`:进入即 self;点场景进 play;打出第一张卡进 friends;第一张卡到点进 done 并显示收尾卡。直接打牌会从 self 跳到 friends。
- 气泡包在 `IgnorePointer` 里,不拦截手牌手势;手牌聚焦时隐藏。self / friends 锚在 `Alignment(0, 0.6)`(自己小人下方的空带,避开示例小人和缩短说明),play 锚在手牌上方。
- 缩短说明在 HUD 下方,仅运动中显示。收尾卡出现后手牌仍可用,再次完成不重复弹出。

## 5. 权衡

- 不用 Remote Config 开关:首启可能离线,拿不到远端值;要关就发版。
- 不给 `OwnActionSessionNotifier` 加 dryRun:正式路径耦合 Ably / pending / history,本地会话更清楚。
- 跳过 / 登录不做二次确认:演示没有可丢失的东西。
- App Review:示例小人昵称带「示例」且不可交互;演示不收集数据,不涉及 `PrivacyInfo.xcprivacy`。

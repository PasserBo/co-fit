# CoFit — Claude Code 项目指南

CoFit 是「虚拟健身房」社交健身 App(Flutter + Firebase + Ably):好友以虚拟小人形式出现在共享房间,实时显示运动状态,通过「打出动作卡牌」开始运动。

## 常用命令

```bash
fvm flutter pub get
fvm flutter run --dart-define=ABLY_API_KEY=xxx --dart-define=ABLY_CLIENT_ID_PREFIX=cofit
fvm flutter test
fvm dart run build_runner build --delete-conflicting-outputs   # freezed 代码生成
fvm flutter analyze
```

## 仓库/基建事实(SSOT)

与本节冲突的记忆/猜测一律以本节为准;发现事实变化时**先更新本节**再动手。

### 工具链

- **Flutter 走 fvm**(`.fvmrc` 锁 3.41.8):一律用 `fvm flutter` / `fvm dart`,不要裸调。
- **firebase CLI 只装在 nodenv 的 Node 20.12.0 里**,当前 shell 版本没有该命令。调用方式:
  `NODENV_VERSION=20.12.0 firebase <cmd> --project cofit-lmdyd`(无 active project,必须显式 `--project`;兜底绝对路径 `$(nodenv root)/versions/20.12.0/bin/firebase`)。
- **CocoaPods 需要 UTF-8 locale**,否则报 `Unicode Normalization not appropriate for ASCII-8BIT`:
  `cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install`。

### Git / CI

- 远端:`git@github.com-personal:PasserBo/co-fit.git`(SSH alias `github.com-personal`),主分支 `main`,git user `PasserBo`。
- ⚠️ **用于提交的 build(TestFlight / App Store)必须从 `main` 打包**:先把要发的分支合进 `main` 并 push,再在 `main` 上、工作区干净、与 `origin/main` 一致的状态下运行 `scripts/build_ipa.sh`(脚本会检查,不满足直接退出)。2026-11-21 定:1.0.0 (4) 是从未合并的分支 `claude/community-basics-ab39ed` 打的包,导致线上版本有「发现公开房间」而 `main` 没有。
- **firestore.rules 的部署走 CI,不要本地 `firebase deploy`**:
  [.github/workflows/deploy-rules.yml](.github/workflows/deploy-rules.yml) 在 push 到 `main` 且 `firestore.rules` 有改动时,用 service account 自动部署到 `cofit-lmdyd`。改完 rules → commit + push → `gh run list --workflow=deploy-rules.yml` 确认 success 即可。
- 部署 rules 前把 diff 贴给用户确认(历史约定)。

### Firebase / 平台

- Firebase 项目 `cofit-lmdyd`,**iOS-only**(无 `android/` 目录,`firebase_options.dart` 仅 iOS 配置)。
- Bundle id **`com.passerbo.cofitapp`**、团队 **`J95TRWHWYM`**(付费,证书 `Apple Development: Yiyang Xu`)。2026-09-16 从旧免费账号的 `com.passerbo.cofit` 迁移——显式 App ID 跨团队全局唯一,旧 id 无法在新团队注册。Firebase iOS app 已换新(`1:154412755372:ios:cfd018…`),旧 app 注册可由用户在 console 删除。
- **上架配置(2026-11-04)**:仅 iPhone(`TARGETED_DEVICE_FAMILY = 1`)+ 仅竖屏;`ITSAppUsesNonExemptEncryption=false`;App 级 `ios/Runner/PrivacyInfo.xcprivacy` 与 App Store Connect 的 App Privacy 表必须一致(改一处同步另一处)。打 TestFlight/App Store 包用 `scripts/build_ipa.sh`(内置 `--dart-define-from-file=.env`)。资料包与文案:[docs/release/app_store_connect_testflight.md](docs/release/app_store_connect_testflight.md)。
- **iOS 插件集成已切到 Swift Package Manager**(`enable-swift-package-manager: true`):8 个插件走 SPM,仅 `ably_flutter` / `sign_in_with_apple` / `Flutter` 走 CocoaPods。所以 `pod install` 显示「3 依赖 / 6 pod」是**正常的**,不是装残。`flutter clean` 后必须先 `flutter build ios --config-only` 再 `pod install`,否则插件列表为空。
- Auth 已启用 provider:**Apple + Google + Email/Password**(Apple 于 2026-09-17 真机验证通过)。
  - ⚠️ **Apple 凭证必须带 `accessToken: appleCredential.authorizationCode`**,只传 `idToken` + `rawNonce` 会报 `invalid-credential / Invalid OAuth response from apple.com`——该文案会把排查引向 Firebase/Apple provider 配置,**实为客户端漏传授权码**(flutterfire#18289 / #13235)。改 `signInWithApple` 时勿删。
  - Apple 侧已配:Services ID、Sign in with Apple 私钥(`.p8` 存本地 `keys/`,已 gitignore)、邮件转发源 `noreply@cofit-lmdyd.firebaseapp.com`。私钥同时是上架「账号删除需 token revocation」的前提。
  - ⚠️ **Apple 登录产生独立 Firebase uid**,与既有 Google/邮箱账号不互通;账号关联(linkWithCredential)待产品决议。
- Firestore 集合(rules 全部显式声明,末尾全局 deny):`rooms`(含 `members{uid}` map,owner 可移出成员)、`users/{uid}`(profile,可选键 `activeDeckId`)、`users/{uid}/memberships`、`users/{uid}/decks`、`users/{uid}/cards`、`users/{uid}/sessions`(只追加打卡日志)、`users/{uid}/session_memos`(运动 memo,本人可建改删)、`card_templates`(只读;**SSOT 在 `firestore/card_templates.json`**,push main 由 `deploy-card-templates.yml` upsert,删多余文档需 workflow_dispatch 开 prune)、`reports`(举报,仅本人 create,客户端不可读)。
- ⚠️ **Firestore `snapshots()` 第一帧可能来自本地缓存**。`RoomInfoEntity.fromCache == true` 的帧只能展示,**不得**据此判定「被移出/已解散」并做清理(2026-10-26 曾因此把刚加入的用户自己踢出房间)。
- ⚠️ **Ably presence**:`watchPresence` 必须先 `subscribe()` 再 `get()`;presence update 是整包替换,永远带 `userId`;自己的运动状态经 `AblyRuntimeNotifier.reassertPresence()` 广播到**所有**已订阅房间,不要只写当前房间。
- Ably key 走 `--dart-define`(`ABLY_API_KEY` / `ABLY_CLIENT_ID_PREFIX`);仓库根 `.env`(gitignored,含真实 key)配合 `.vscode/launch.json` 的 `--dart-define-from-file` 使用。**不要把 key 写进任何被提交的文件。**
- **功能开关走 Firebase Remote Config**(`lib/core/flags/`):`FeatureFlags` 的字段默认值 = 远端未配置时的行为;Google 登录由 `auth_google_enabled` 控制,**默认关**(2026-10-26 决议:代码保留不删)。要打开:console 新建同名布尔参数并发布。
- **AI 教练 Beta**(change `add-ai-coach-beta`,2026-11-18):运动历史页入口,`beta_ai_coach_enabled` 默认关,**debug 构建始终可见**。模型走 **Firebase AI Logic**(`firebase_ai` **锁 4.x**——5.x 需 firebase_core 5 / Flutter 3.44),App 内无模型密钥;UI 由 A2UI(`a2ui_flutter`/`a2ui_core`/`a2ui_agent` 0.x,版本同时写在 `CoachChatController.packageVersions`)渲染。会话日志 JSONL 存 `Documents/ai_coach_logs/`,汇总 `fvm dart run tool/summarize_ai_coach_log.dart <log>`。⚠️ 运动记录会发给 Google:**开放给外部测试者前必须先同步隐私政策 / PrivacyInfo / ASC App Privacy 并启用 App Check**(tasks M3)。
- **今日面板**(change `add-home-sheet`,2026-11-21,进行中):房间页下半部分的可收起面板,展开时自己的小人站在面板上沿;收起后点自己的小人重新展开。代码在 `lib/features/home_sheet/`(规则纯函数在 `domain/`、`usecase/`;`HomeStageController` 用一个展开程度驱动面板、手牌下沉、好友区域)。自己的小人不在 `RoomScene` 里,而在房间页的独立一层(`showSelf: false`),切换房间时不动。模块清单 / 顺序 / 自动展开规则走 Remote Config **字符串**参数 `home_sheet_layout`(JSON,形状见该 change 的 design.md §12;空串 = 内置默认,`modules: []` = 关闭面板)。debug 构建面板末尾有占位模块(带动画慢放开关)。
- **今日进度**(change `add-daily-card-goal`,2026-11-25,进行中):今日面板的 `daily_progress` 模块 + 运动历史页顶部。代码在 `lib/features/daily_goal/`:计量方式(`DailyProgressMetric`,内置 `cards` / `minutes`)、目标、进度计算、展示四者互不依赖。内容走 Remote Config **字符串**参数 `daily_goal_config`(JSON:`metric` / `defaultTarget` / `choices`,空串 = 内置默认 张数 / 2 / 1·2·3·5·8)。用户选的目标**只存本机**(按用户 + 计量方式分键),不写 Firestore。模块显示的进度与算出来的进度分开:等今日面板的庆祝节拍到了才滚到新值。
- **运动 memo**(change `add-workout-memo`,2026-11-25,进行中):做完一张卡后今日面板最上方的 `last_session_memo` 模块(感受一次点击 / 可选一句话,全部可跳过;**不问次数**——「量」属于卡片,见提案 `add-card-prescription`),运动历史行露出 memo 并可点开编辑。代码在 `lib/features/workout_memo/`。数据在 `users/{uid}/session_memos/{sessionId}`(文档 id = 运动记录 id)——**与 `sessions` 分开**:sessions 只追加不可改,memo 可改可删;全空的 memo 不保存(改为删除)。存的是感受档位的 **key**,文案 / 表情在配置里。内容走 Remote Config **字符串**参数 `workout_memo_config`(JSON,形状见该 change 的 design.md §3)。⚠️ 账号删除的清理列表(`FirebaseUserDataEraser._subcollections`)里有它;以后再加用户子集合必须同步加进去。
- **卡片自带「做多少」**(change `add-card-prescription`,2026-11-25,进行中):卡片的 `intensityBaseline` = `{label?, amounts?: [{kind, value, unit}]}`,强度标签与量都可选,一张卡可带几项(种类清单 `CardAmountKind.all`:次数 / 重量 / 距离,是内容;**没有组数**——一张卡就是一组)。完成时把当时的强度与量**抄一份**进运动记录(`intensityLabel`、`amounts`,可选键),本机快照 `PendingSessionSnapshot` 也带着,保证被结束后补记的记录不丢。⚠️ 用户决议:**「量」不在运动完成后填**,memo 不问次数。量只是参考,不影响倒计时。
- **法律文档**在 `docs/legal/`,随 main 推送由 GitSpec 工作流发布到 GitHub Pages;App 内地址只在 `lib/core/legal/legal_links.dart`(GitSpec slug 规则 `docs/legal/privacy.md` → `/co-fit/docs-legal-privacy`,改文件名必须同步改这里)。
- 深链:自定义 scheme **`cofit://room/<roomId>?h=<shareLinkHash>`**(拼装/解析唯一事实源 `lib/features/invite/domain/invite_link_format.dart`;Info.plist 已注册 `cofit` 与 Google 回跳两条 scheme)。本期无 Universal Links。
- **账号删除**(Apple 上架强制):`profile/usecase/delete_account_usecase.dart`。⚠️ 顺序不可调换——Firestore 清理必须在注销 Auth 用户**之前**,uid 失效后 rules 会拒绝一切写入、数据永久残留(已有单测锁住顺序)。Apple 账号会重新授权取新鲜 authorizationCode 用于 `revokeTokenWithAuthorizationCode`;邮箱账号无法静默重认证 → 抛 `ReauthenticationRequiredException`,UI 引导重登。

## 架构(SSOT)

**[.cursor/rules/flutter_architecture.mdc](.cursor/rules/flutter_architecture.mdc) 是前端架构的唯一权威文档**,与任何文档冲突时以它为准。要点:

- Clean Architecture:`domain/`(entity + repository 接口)← `usecase/` ← `presentation/` 与 `infrastructure/`(repository 实现)。
- Riverpod provider 是 DI 接线,放 `provider/`,不算独立分层。
- 纯展示组件(不 `ref.watch`)放 `presentation/widget/`;页面级(读 provider)放 `presentation/view/`。
- entity 用 `@freezed`;repository 接口在 domain,实现在 infrastructure。
- 现状约定:repository 实现实际放各 feature 的 `data/`(历史沿用,不迁移);action 特性旧 usecase 在 `domain/` 下(遗留,不迁移),新 usecase 一律放 `usecase/`。

已实现 feature:`room`(房间 CRUD/建房页/公开房间发现与搜索/presence/事件折叠/成员管理/举报/实时感知被移出与解散)、`auth`(Apple+Google+邮箱登录、bootstrap)、`profile`(资料/onboarding/账号删除)、`invite`(邀请深链)、`action`(动作卡模板/自建卡/牌组云端化/打卡历史/会话被杀恢复)、`avatar`(豆豆骨架引擎:Rig/MotionClip/PoseSampler,动作是数据不是代码,见 `docs/avatar_bean_spec.md`)、`ai_coach`(beta:A2UI 生成式 UI + Firebase AI Logic)、`home_sheet`(今日面板:台子 / 模块注册表 / 今日推荐,进行中)、`daily_goal`(今日进度:每日清零的进度与目标,进行中)、`workout_memo`(运动 memo:感受 / 次数 / 一句话,进行中)。`social` 仍是空目录。

**架构总览(现状)与踩坑清单:[docs/project_overview.md](docs/project_overview.md);用户流程与页面完成度:[docs/flows_status.md](docs/flows_status.md)。** 产品提案 / 行为规格 / 任务看板走 `solo-spec` skill,根目录 [docs/spec/](docs/spec/SPEC_SYSTEM.md)(随 docs 一起发布到 GitHub Pages,**内容公开**);产品讨论出结论、开始/结束一个 change 时先更新那里。 跨 feature 纯 UI 组件放 `lib/core/widget/`(确认弹窗一律用 `showCoFitConfirmSheet`,不要再写原生 AlertDialog;AppBar 里的主按钮一律用 `AppBarFilledAction`,直接放 `FilledButton` 会撑坏工具栏导致返回键失灵)。

- `dart format` 只跑在自己改的文件上,整目录 format 会把大量未格式化的历史文件卷进 diff。

## UI 大改造(进行中)

设计定稿与交接说明在 [docs/README.md](docs/README.md),视觉参考在 [docs/design_reference.html](docs/design_reference.html)(定稿锚点:`#6b` 主界面、`#12b` 牌库、`#13a` token 表)。进度与数据缺口记录在 [docs/ui_overhaul/STATUS.md](docs/ui_overhaul/STATUS.md)。

**任何 UI 实现/改造任务,先调用 `ui-implementation` skill;涉及新增或修改设计数值(颜色/间距/圆角/字体等)时,调用 `design-tokens` skill。** 核心铁律(细节见 skill):

1. 组件只引用语义 token(`Theme.of(context).extension<CoFitColors>()!` 等),**禁止裸 hex、禁止 magic number**。
2. 新数值先进 [lib/core/theme/tokens/cofit.tokens.json](lib/core/theme/tokens/cofit.tokens.json)(W3C DTCG 格式),再同步到 Dart theme 文件。
3. 不照搬 HTML 参考稿的绝对尺寸——按响应式规则实现,兼容不同设备。
4. 做功能组件前先读该 feature 的 `domain/entity/` 与数据模型,按数据模型设计。
5. 设计与数据模型不匹配时,**停下来问用户**,不要擅自决定。
6. 设计中尚无对应功能的组件:按 stub 协议做简单组件 + 预估数据模型 + 简单跳转,并登记到 STATUS.md。

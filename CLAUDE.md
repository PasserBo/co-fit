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
- **firestore.rules 的部署走 CI,不要本地 `firebase deploy`**:
  [.github/workflows/deploy-rules.yml](.github/workflows/deploy-rules.yml) 在 push 到 `main` 且 `firestore.rules` 有改动时,用 service account 自动部署到 `cofit-lmdyd`。改完 rules → commit + push → `gh run list --workflow=deploy-rules.yml` 确认 success 即可。
- 部署 rules 前把 diff 贴给用户确认(历史约定)。

### Firebase / 平台

- Firebase 项目 `cofit-lmdyd`,**iOS-only**(无 `android/` 目录,`firebase_options.dart` 仅 iOS 配置)。
- Bundle id `com.passerbo.cofit`(pbxproj 三个构建配置 + RunnerTests `com.passerbo.cofit.RunnerTests`),由用户**个人 Apple 账号**持有(升级付费中,期间免费签名 7 天描述文件,Team `Q4C958AWVT`)。
- Auth 已启用 provider:**Google + Email/Password**。**Sign in with Apple 延后(E1-Apple 轨道)**:免费账号无此 capability,等付费账号就绪;⚠️ 上架前硬性阻塞(App Store 规则:有第三方登录必须有 Apple 登录)。登录页已为 Apple 按钮预留首位。
- Firestore 集合(rules 全部显式声明,末尾全局 deny):`rooms`、`users/{uid}`(profile,可选键 `activeDeckId`)、`users/{uid}/memberships`、`users/{uid}/decks`、`users/{uid}/sessions`(只追加打卡日志)、`card_templates`(只读)。
- Ably key 走 `--dart-define`(`ABLY_API_KEY` / `ABLY_CLIENT_ID_PREFIX`);仓库根 `.env`(gitignored,含真实 key)配合 `.vscode/launch.json` 的 `--dart-define-from-file` 使用。**不要把 key 写进任何被提交的文件。**
- 深链:自定义 scheme **`cofit://room/<roomId>?h=<shareLinkHash>`**(拼装/解析唯一事实源 `lib/features/invite/domain/invite_link_format.dart`;Info.plist 已注册 `cofit` 与 Google 回跳两条 scheme)。本期无 Universal Links。
- 上线前遗留:google_fonts 运行时拉取 Space Grotesk 需改打包进 assets(STATUS.md 决议)。

## 架构(SSOT)

**[.cursor/rules/flutter_architecture.mdc](.cursor/rules/flutter_architecture.mdc) 是前端架构的唯一权威文档**,与任何文档冲突时以它为准。要点:

- Clean Architecture:`domain/`(entity + repository 接口)← `usecase/` ← `presentation/` 与 `infrastructure/`(repository 实现)。
- Riverpod provider 是 DI 接线,放 `provider/`,不算独立分层。
- 纯展示组件(不 `ref.watch`)放 `presentation/widget/`;页面级(读 provider)放 `presentation/view/`。
- entity 用 `@freezed`;repository 接口在 domain,实现在 infrastructure。
- 现状约定:repository 实现实际放各 feature 的 `data/`(历史沿用,不迁移);action 特性旧 usecase 在 `domain/` 下(遗留,不迁移),新 usecase 一律放 `usecase/`。

已实现 feature:`room`(房间/Presence/事件/退出房间)、`auth`(Google+邮箱登录)、`profile`(用户资料/onboarding)、`invite`(邀请深链)、`action`(动作卡模板/牌组云端化/打卡历史)、`avatar`(占位小人动作集)。`social` 仍是空目录。

## UI 大改造(进行中)

设计定稿与交接说明在 [docs/README.md](docs/README.md),视觉参考在 [docs/design_reference.html](docs/design_reference.html)(定稿锚点:`#6b` 主界面、`#12b` 牌库、`#13a` token 表)。进度与数据缺口记录在 [docs/ui_overhaul/STATUS.md](docs/ui_overhaul/STATUS.md)。

**任何 UI 实现/改造任务,先调用 `ui-implementation` skill;涉及新增或修改设计数值(颜色/间距/圆角/字体等)时,调用 `design-tokens` skill。** 核心铁律(细节见 skill):

1. 组件只引用语义 token(`Theme.of(context).extension<CoFitColors>()!` 等),**禁止裸 hex、禁止 magic number**。
2. 新数值先进 [lib/core/theme/tokens/cofit.tokens.json](lib/core/theme/tokens/cofit.tokens.json)(W3C DTCG 格式),再同步到 Dart theme 文件。
3. 不照搬 HTML 参考稿的绝对尺寸——按响应式规则实现,兼容不同设备。
4. 做功能组件前先读该 feature 的 `domain/entity/` 与数据模型,按数据模型设计。
5. 设计与数据模型不匹配时,**停下来问用户**,不要擅自决定。
6. 设计中尚无对应功能的组件:按 stub 协议做简单组件 + 预估数据模型 + 简单跳转,并登记到 STATUS.md。

# CoFit — Claude Code 项目指南

CoFit 是「虚拟健身房」社交健身 App(Flutter + Firebase + Ably):好友以虚拟小人形式出现在共享房间,实时显示运动状态,通过「打出动作卡牌」开始运动。

## 常用命令

```bash
flutter pub get
flutter run --dart-define=ABLY_API_KEY=xxx --dart-define=ABLY_CLIENT_ID_PREFIX=cofit
flutter test
dart run build_runner build --delete-conflicting-outputs   # freezed 代码生成
flutter analyze
```

## 架构(SSOT)

**[.cursor/rules/flutter_architecture.mdc](.cursor/rules/flutter_architecture.mdc) 是前端架构的唯一权威文档**,与任何文档冲突时以它为准。要点:

- Clean Architecture:`domain/`(entity + repository 接口)← `usecase/` ← `presentation/` 与 `infrastructure/`(repository 实现)。
- Riverpod provider 是 DI 接线,放 `provider/`,不算独立分层。
- 纯展示组件(不 `ref.watch`)放 `presentation/widget/`;页面级(读 provider)放 `presentation/view/`。
- entity 用 `@freezed`;repository 接口在 domain,实现在 infrastructure。

已实现 feature:`room`(房间/Presence/事件)、`auth`(登录)、`action`(动作卡模板)。`social`、`avatar`、`profile` 目前是空目录。

## UI 大改造(进行中)

设计定稿与交接说明在 [docs/README.md](docs/README.md),视觉参考在 [docs/design_reference.html](docs/design_reference.html)(定稿锚点:`#6b` 主界面、`#12b` 牌库、`#13a` token 表)。进度与数据缺口记录在 [docs/ui_overhaul/STATUS.md](docs/ui_overhaul/STATUS.md)。

**任何 UI 实现/改造任务,先调用 `ui-implementation` skill;涉及新增或修改设计数值(颜色/间距/圆角/字体等)时,调用 `design-tokens` skill。** 核心铁律(细节见 skill):

1. 组件只引用语义 token(`Theme.of(context).extension<CoFitColors>()!` 等),**禁止裸 hex、禁止 magic number**。
2. 新数值先进 [lib/core/theme/tokens/cofit.tokens.json](lib/core/theme/tokens/cofit.tokens.json)(W3C DTCG 格式),再同步到 Dart theme 文件。
3. 不照搬 HTML 参考稿的绝对尺寸——按响应式规则实现,兼容不同设备。
4. 做功能组件前先读该 feature 的 `domain/entity/` 与数据模型,按数据模型设计。
5. 设计与数据模型不匹配时,**停下来问用户**,不要擅自决定。
6. 设计中尚无对应功能的组件:按 stub 协议做简单组件 + 预估数据模型 + 简单跳转,并登记到 STATUS.md。

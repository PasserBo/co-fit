---
name: ui-implementation
description: CoFit UI 大改造的实现工作流。凡是"实现/改造某个页面、组件、界面 UI"、"按设计稿开发"、"还原设计"类任务(implement UI / build screen / redesign)都必须先使用本 skill,按其流程执行。
---

# CoFit UI 实现工作流

按顺序执行以下步骤。跳步(尤其是跳过第 2、3 步直接写 UI)是本项目最常见的返工原因。

## 第 0 步:前置阅读

- [docs/README.md](../../../docs/README.md) — 设计交接说明(屏幕规范、交互、保真度要求)。
- [.cursor/rules/flutter_architecture.mdc](../../../.cursor/rules/flutter_architecture.mdc) — 架构 SSOT,决定文件放哪。
- [docs/ui_overhaul/STATUS.md](../../../docs/ui_overhaul/STATUS.md) — 当前进度、已知数据缺口、历史决议。**先看这里,避免重复提问已有决议的问题。**

## 第 1 步:读设计稿

`docs/design_reference.html` 是 JS bundle(内容以转义字符串内嵌),**不能直接 Read 全文**(400KB)。两种查阅方式:

1. **浏览器(推荐,看视觉)**:用 Browser 工具打开该文件,页面锚点即设计编号(`#6b`、`#12b`、`#13a`)。
2. **grep(取精确数值)**:锚点 id 在文件里是转义形式,用如下方式截取某一稿的源码片段:
   ```bash
   grep -o 'id=\\"12b\\".\{0,6000\}' docs/design_reference.html
   ```

定稿只有三处:`#6b` 房间主界面、`#12b` 牌库、`#13a` 颜色 token 表;其余锚点是过程稿,仅作参考。`#t10`(我的页)两版均未定稿——实现前必须先问用户选 10a 还是 10b。

## 第 2 步:调查功能现状(数据模型优先)

写任何 UI 前,先回答"这个界面展示/操作的数据,现在的代码里长什么样":

```bash
ls lib/features/<feature>/domain/entity/ lib/features/<feature>/domain/ lib/features/<feature>/usecase/
```

- 读相关 entity(如 `action_template_card.dart`、`room_presence_member.dart`)、repository 接口、usecase。
- 确认字段名、类型、可空性、取值范围(必要时查 `firestore.rules`、repository 实现里的字段读取)。
- **UI 按 entity 设计,不按设计稿的示例文案设计。** 设计稿里的假数据(卡片名、人名)只是占位。

## 第 3 步:建立 设计 ↔ 数据 映射表

对照第 1、2 步结果,列一张映射表(写进你的实现说明或 PR 描述):

| 设计元素 | 数据来源 | 状态 |
|---|---|---|
| 卡片名称 | `ActionTemplateCard.name` | ✅ 已有 |
| 卡片时长 | `ActionTemplateCard.defaultDurationSec` | ✅ 已有 |
| 卡片来源徽章(官方/自建/好友分享) | 无对应字段 | ❌ 缺口 |

每个缺口归入两类之一,处理方式不同:

### 3a. 不匹配(功能已有,但字段/结构对不上)→ 问用户

设计需要的数据在已有 entity 中缺失、类型不符、或语义冲突时,**停下来用 AskUserQuestion 问用户**,给出选项,例如:扩展 entity(需要动 Firestore 数据/rules)/ 先用 stub 占位 / 调整设计。把决议记入 `docs/ui_overhaul/STATUS.md` 的「决议记录」。

已知待确认的缺口见 STATUS.md,典型例子:
- `ActionTemplateCard.type` 是自由 String,设计需要 strength/cardio/core/flexibility 四类枚举(决定类型色条颜色)。
- 卡片「来源」(官方/自建/好友分享)无字段。
- 「牌组 deck」entity 不存在(牌库页「我的卡组」tab 依赖它)。

### 3b. 功能整体未实现(如好友分享、牌组管理)→ stub 协议

不等后端/功能开发,按以下协议先做出可导航的简单版本:

1. **预估数据模型**:在 `lib/features/<feature>/domain/entity/` 建 entity,照常用 `@freezed`,类名不加特殊后缀,但文件顶部加注释 `// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认`。字段取设计稿所需的最小集合。
2. **In-memory repository**:接口照常放 `domain/`,实现放 `data/`(或 `infrastructure/`,跟随该 feature 现状),返回写死的示例数据。参考现有先例 [in_memory_action_template_selection_repository.dart](../../../lib/features/action/data/in_memory_action_template_selection_repository.dart)。
3. **简单页面 + 跳转**:页面只做布局与静态数据展示,用 `Navigator.push` 完成基本跳转,交互可以是 no-op + SnackBar「开发中」。
4. **登记**:在 STATUS.md 的「Stub 登记表」加一行(feature、draft entity、待办)。

## 第 4 步:token 先行

实现中需要的每一个颜色、间距、圆角、字号、动效数值:

1. 先在现有 token 里找(`lib/core/theme/tokens/cofit.tokens.json` + `cofit_colors.dart`)。
2. 找不到 → 调用 **design-tokens** skill 新增(JSON 先行,再同步 Dart),然后才能在组件里引用。
3. **组件代码里不出现裸 hex、不出现无名数字**(`EdgeInsets.all(13)` 这类 magic number 一律不行;`SizedBox(height: CoFitDimens.spacingMd)` 或 token 常量才行)。唯一例外:`0`、`1` 这类结构性数值和 flex 比例。

颜色一律 `final c = Theme.of(context).extension<CoFitColors>()!;`,禁止 `CoFitPalette.*` 直接出现在 feature 代码中(palette 只供 theme 层引用)。

## 第 5 步:响应式实现规则

参考稿按 iPhone 单一宽度绘制,**它的 px 是"意图",不是常量**。翻译规则:

**可以固定(经 token)**:
- 小元素尺寸:图标块、徽章、状态点、描边宽、圆角、模糊半径。
- 间距刻度:用 spacing token,不随屏幕缩放。

**必须弹性**:
- 容器宽高:禁止给卡片/面板写死宽度。横向卡片列用固定**子项宽度 token + 横向滚动**,或 `LayoutBuilder` 按可用宽度算列数。
- 全屏布局:比例定位用 `FractionallySizedBox` / `Align`,列表用 `Expanded`,禁止依据 844×390 反推的绝对坐标。
- 文本:预留换行/省略(`overflow: TextOverflow.ellipsis`),不能假设固定字符数。

**硬性要求**:
- 所有页面根部处理 `SafeArea`(沉浸式主界面自行处理 padding,也要读 `MediaQuery.paddingOf`)。
- 支持系统字体缩放:布局不能在 `textScaleFactor 1.3` 下溢出(小屏 + 大字是验收场景)。
- 可点击目标 ≥ 44×44(`size.minTapTarget` token)。
- 验收视口:小屏 375×667、标准 390×844、大屏 430×932。至少在最小和最大两档确认不溢出、不错位。

## 第 6 步:落文件(架构位置)

- 纯展示组件(不 `ref.watch`)→ `presentation/widget/`;页面级 → `presentation/view/`(旧代码直接平铺在 `presentation/` 下,新文件按新规范放子目录)。
- 跨 feature 复用的纯 UI 组件(如动作卡片)放它所属的 feature(卡片属于 `action`),其他 feature 通过 import 使用;不确定归属时问用户。
- provider/usecase/entity 位置严格按 [flutter_architecture.mdc](../../../.cursor/rules/flutter_architecture.mdc) 的决策树。

## 第 7 步:验证与收尾

1. `flutter analyze` 零新增告警;涉及 freezed 时跑 build_runner。
2. 纯展示组件补 widget test(先例:`test/features/room/presentation/widgets/`)。
3. 更新 [docs/ui_overhaul/STATUS.md](../../../docs/ui_overhaul/STATUS.md):屏幕进度、新 stub、新决议。
4. 汇报时列出:实现了什么、映射表、留下的缺口/问题。

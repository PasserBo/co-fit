---
name: design-tokens
description: 管理 CoFit 设计 token(W3C DTCG JSON + Flutter ThemeExtension)。新增/修改颜色、间距、圆角、字号、透明度、动效数值时,或发现组件里需要写死数值(magic number / 裸 hex)时使用。
---

# CoFit 设计 token 管理

## 双文件制:JSON 是设计事实源,Dart 是消费层

| 文件 | 角色 |
|---|---|
| [lib/core/theme/tokens/cofit.tokens.json](../../../lib/core/theme/tokens/cofit.tokens.json) | **W3C DTCG 格式**的设计事实源(source of truth)。所有设计数值先在这里定义。 |
| [lib/core/theme/cofit_colors.dart](../../../lib/core/theme/cofit_colors.dart) | 颜色 token 的 Flutter 实现(`ThemeExtension<CoFitColors>`),组件唯一的颜色入口。 |
| `lib/core/theme/cofit_dimens.dart` 等 | 非颜色 token(间距/圆角/尺寸/动效)的 Dart 承载。**尚未创建**——首次需要时创建,静态常量类即可,不必是 ThemeExtension。 |

**修改流程(顺序不可倒)**:

1. 改/加 `cofit.tokens.json`(DTCG 格式,见下)。
2. 同步到对应 Dart 文件,保持字段名与 JSON path 可对应(`primary.subtle` → `primarySubtle`)。
3. 组件里只引用 Dart token,永不复制数值。

两边不一致时以 JSON 为准修 Dart;若发现 Dart 里有 JSON 没有的值,反向补进 JSON。

## DTCG 格式要点

- 每个 token 是 `{"$value": ..., "$type": ...}`,`$type` 可在 group 上声明并继承。
- 别名引用:`"$value": "{color.lime.400}"`。**语义层尽量用别名指向 palette,不重复 hex。**
- 带透明度的颜色用 8 位 hex(`#C8F24B29`),并在 `$description` 写明"基色 @百分比"(Dart 侧用 `withValues(alpha: x)` 实现,以 alpha 百分比为准,hex8 是近似记录)。
- dimension 用对象形式:`{"$value": {"value": 16, "unit": "px"}}`(Flutter 侧即逻辑像素 double)。
- 来自定稿的值在 `$description` 标注出处(如 `13a`、`README`);自定的种子值标 `seed v1`。

## 命名与分层

**两层结构,组件只许引用语义层:**

1. **palette 层**(`color.lime.400` 等)— 原始色板,只供 theme 文件内部引用。
2. **语义层** — 按用途命名,不按外观命名:
   - `primary.*`(main/on/subtle/border/pressed)
   - `bg.*`(app/surface/overlay/deep)、`border.*`(subtle/strong/focus)
   - `text.*`(primary/secondary/tertiary/disabled)
   - `status.*`(active/paused/idle/danger/info)
   - `type.*`(strength/cardio/core/flexibility,各带 `*Subtle`)— 动作类型色
   - `spacing.*`、`radius.*`、`size.*`、`borderWidth.*`、`opacity.*`、`typography.*`、`motion.*`

新 token 命名自检:换一个视觉主题这个名字还成立吗?`coralBadge` ❌ → `status.danger` ✅。

## 固定的 alpha 规则(来自设计定稿,新增淡色时必须沿用)

| 用途 | alpha |
|---|---|
| 淡底(subtle 背景) | 主色 @16% |
| 淡描边 | 主色 @40% |
| 选中光晕(glow) | 主色 @18% |
| 文字层级 | gray-50 @70 / 50 / 42% |
| 分隔线/描边 | white @7–9% |
| overlay(需配 blur 8) | gray-850 @62% |

## 新增 token 的判定流程

1. **先复用**:grep JSON 里现有 token;间距/圆角优先落到已有刻度(spacing 4/8/12/16/20/24/32,radius 8/12/16)。
2. 设计稿出现刻度外的新值:相差 ≤2px 时吸附到最近刻度;确属新档位(或 `#13a` token 表里有而 JSON 里没有)才新增。
3. **无法归类、或会打破现有刻度体系的值 → 问用户再动手**,决议记入 [docs/ui_overhaul/STATUS.md](../../../docs/ui_overhaul/STATUS.md)。
4. 新增后:JSON + Dart 两处落地,并在改动说明里列出新 token 清单。

## 组件侧引用方式

```dart
final c = Theme.of(context).extension<CoFitColors>()!;   // 颜色,唯一入口
// CoFitPalette.* 禁止出现在 feature 代码中
```

禁止:裸 hex、`Colors.*`(除 `Colors.transparent`)、无名数字尺寸。允许的字面量仅限 `0`/`1` 等结构性数值与 flex 比例。

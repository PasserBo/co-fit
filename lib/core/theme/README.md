# core/theme — 设计 token

| 文件 | 角色 |
|---|---|
| `tokens/cofit.tokens.json` | W3C DTCG 格式的设计事实源。**所有设计数值先在这里定义/修改**,再同步 Dart。 |
| `cofit_colors.dart` | 颜色 token 的 Flutter 实现(`ThemeExtension<CoFitColors>`),feature 代码的唯一颜色入口。 |
| `cofit_dimens.dart` | 间距/圆角/尺寸/动效/字重等非颜色 token 的静态常量(`CoFitDimens` / `CoFitMotion` / `CoFitFontWeights`)。 |
| `cofit_theme.dart` | 全局深色 `ThemeData`(注册 CoFitColors extension、Space Grotesk 字体),`main.dart` 唯一主题入口。 |

规则与流程详见 `.claude/skills/design-tokens/SKILL.md`。要点:

- feature 代码只引用语义 token(`Theme.of(context).extension<CoFitColors>()!` / dimens 常量),禁止裸 hex 与 magic number,禁止直接使用 `CoFitPalette`。
- JSON 与 Dart 不一致时,以 JSON 为准修 Dart。

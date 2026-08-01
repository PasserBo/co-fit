# Handoff: CoFit — 虚拟健身房社交应用(定稿设计)

## Overview
CoFit 是一个「虚拟健身房」社交健身 App(Flutter + Firebase):好友以虚拟小人形式出现在共享房间里,实时显示运动状态;用户通过「打出动作卡牌」开始运动。本包汇总目前已定稿的设计,供 Claude Code 在现有 CoFit Flutter 仓库中实现。

## About the Design Files
`design_reference.html` 是 **HTML 设计参考稿**(打开即可看到全部探索过程,新的在上面)——它展示预期的外观与行为,**不是可直接复制的生产代码**。任务是:在 CoFit 仓库现有架构(`lib/features/<feature>/` 结构、Firebase/Ably 服务层)中用 Flutter **重新实现**这些设计。

## Fidelity
**高保真(hifi)**。颜色、字重、圆角、间距均为最终意图,请像素级还原;所有颜色一律引用 `cofit_colors.dart` 中的 `CoFitColors` 语义 token(已按仓库习惯写成 `ThemeExtension`,建议放 `lib/core/theme/`),**禁止在组件里写裸 hex**。

字体:英文/数字用 Space Grotesk(标题 700,标签 600),中文跟随系统字体。深色主题唯一。

## 全局设计语言
- 深色底(`bg.app` #181B22)+ 荧光绿品牌色(`primary.main` #C8F24B),点缀 coral/amber/blue。
- 卡片容器:`bg.surface` #22252E,圆角 12–16,描边 `border.subtle` white@7%。
- 选中/焦点:`border.focus` lime 1.5px 描边 + 微光晕(lime@18% glow)。
- 淡底徽章:主色 @16% 底 + @40% 描边 + 主色文字(如「运动中」「官方」)。

## Screens / Views(按导航层级)

### 1. 主界面「房间」(定稿 6b,参考稿 #6b)
- **Purpose**: 打开 App 即满屏看到好友活跃状态;左右滑切换房间。
- **Layout**: 全屏沉浸场景,无底部 nav。漂浮气泡空间:好友小人带光圈(状态色)漂浮,越活跃光圈越亮。顶部左上=房间名,右上=第几间房指示点。
- **好友小人状态色**: 运动中 `status.active` lime(呼吸动画 breathe 1.05x)、暂停 `status.paused` amber、挂机 `status.idle` gray-500。
- **底部扇形手牌**(牌组当前卡): 点扇形 → 聚焦模式(卡组放大上浮、背景压暗 scrim,左右滑/点侧牌聚焦中间卡,点背景关闭)= 5d。上滑中间卡 = 打出(开始运动)。
- **牌组切换** = 4a: 点牌组标签 → 悬浮下拉列常用牌组 + 「查看更多」→ 底部抽屉浏览全部。悬浮层不挤压布局。

### 2. 悬浮 dock(全局导航,参考稿 #t9/#12b 左上)
- 左上角悬浮胶囊(`bg.overlay` gray-850@62% + backdrop blur 8px,圆角 16)。
- **收起态**: 只显示当前页图标一枚(lime@16% 圆底 + lime 描边)。点它展开全部目的地(竖向,各页固定槽位),再点收起;5 秒无操作自动收起。
- 目的地: 房间(主界面)、牌库、我的。工具页下钻用压栈 + 明确返回按钮。

### 3. 牌库主页(定稿 12b ✓,参考稿 #12b)
- **Purpose**: TCG 式总牌库:官方默认卡 + 自建卡 + 好友分享卡;从库里组卡组。
- **Layout**: 顶部标题行「牌库」+ 右侧「创建卡片 +」按钮(lime 淡底徽章样式)。其下 segmented 切换:**牌库 / 我的卡组** 两个 tab。
- **牌库 tab**: 按类型分区(力量/有氧/核心/柔韧),每区标题 + 横向滑动卡片列;区顶可再用类型 chip 筛选(选中 chip = lime 实底 + `primary.on` 文字)。
- **我的卡组 tab**: 每套卡组一行(叠牌缩略 + 名称 + 张数/时长),点开展开编辑。
- **卡片交互**: 点卡 → 详情/加入卡组;卡上分享按钮 → 分享给好友。

### 4. 动作卡片(核心组件,全 App 复用)
卡片解剖(从上到下):
1. **类型色条** 顶部 4–5px:`type.strength` coral / `type.cardio` lime / `type.core` amber / `type.flexibility` blue。
2. **图标块** 26px 圆角 8,底色 = 类型色 @16%(`type.*Subtle`)。
3. **名称** Space Grotesk 700。
4. **底行**: 左=「类型 · 来源」小字(类型色),右=时长(如 10min)。
- 来源三种: 官方 / 自建 / 好友分享(徽章)。
- **已入组态**: `border.focus` lime 1.5px + lime@18% 外发光 + ✓ 角标。
- ⚠ 有氧卡类型色 = 品牌色同为 lime-400,其选中态**必须**靠 ✓ 角标区分,不能只靠绿框。
- **移除角标**(编辑态): 右上 -6px 悬浮 19px 圆,`status.danger` coral-500 底白 ×。

### 5. 「我的」/ 个人设置(参考稿 #t10 — 10a/10b 两版均未定稿)
下钻工具页,顶部明确返回。两版共同点:承接 Firebase 登录(Apple/Google),退出登录为 `status.danger` 红字独立卡片。实现时先向产品确认选 10a(形象优先)还是 10b(清单优先)。

## Interactions & Behavior
- 悬浮层(下拉/抽屉/聚焦)一律覆盖在场景之上,**不挤压推开布局**。
- 扇形聚焦: 打开 = 放大上浮 + scrim;关闭 = 点背景。
- dock: 点当前图标展开/收起,5s 自动收起;展开时各目的地固定槽位(肌肉记忆)。
- 动画: 小人 bob(上下 5px 浮动)、运动中光圈 breathe(scale 1→1.055)。

## 小人动作动画(Avatar Motion Set,参考稿 #14a)
动画**只按 4 个卡牌类型走通用原型**,不细分具体动作;自建卡选类型即自动获得动画。差异化仅两个参数:节奏倍率(慢/标准/快 → 时长 ×1.3/×1/×0.75)和光圈类型色。

**形体**(与房间形象一致): 白色 gray-50;圆头(带 2.5px 状态色头环)+ 胶囊躯干 + **短粗四肢、与躯干分离悬浮**(间隙 ~4px)。待机/暂停无手臂,运动时出现短臂。地面光圈 = 类型色 @16–28%。

**状态机**: 待机 →(打出卡牌)→ 起手 0.4s ×1 → 运动 loop(按类型)⇄ 暂停 →(时长结束)→ 完成 1.1s ×1 → 待机。

| 状态 | 关键帧(0% → 50% → 100%) | 时长/缓动 |
|---|---|---|
| 待机 idle | 整体 translateY 0 → −5px → 0 | 2.4s ease-in-out loop |
| 起手 | 卡飞入 0.5s;整体 scale 1→1.16→1 回弹;光圈 burst scale .5→2 淡出 ×1 | 0.4s overshoot |
| 力量·蹲起 | 上身 translateY 0→10px;腿 scaleY 1→.58(origin 脚底);臂 rotate 10°→75°(origin 肩) | 1.3s ease-in-out loop |
| 有氧·原地跑(侧视) | 整体前倾 8° + hop −2.5px(2 倍频);腿 rotate −32°→+32°(origin 髋);臂 rotate +35°→−35°(origin 肩) | 0.6s ease-in-out loop |
| 核心·支撑(侧视) | 静姿 + 整体 translateY 0→1.6px 微颤 | 0.9s ease-in-out loop |
| 柔韧·伸展 | 上身 rotate 0→−16°(origin 髋),顶点停留 20%;单臂固定过头(−150° origin 肩) | 2.6s ease-in-out loop |
| 暂停 | 整体 rotate ±5°(origin 脚底),透明度 75%,头环转 amber | 3s ease-in-out loop |
| 完成 | 跳 −16px + 二段小跳;双臂 rotate 0→150°;光圈 burst ×2 | 1.1s overshoot ×1 |

### ⚠ 关键帧同步规范(必读)
房间内多个小人同屏,肢体相位极易漂移(hot reload / widget 重建 / 分别启动的动画时钟都会导致左右肢从「交替」变「同步」)。规则:

1. **每个小人每个状态只用一个 AnimationController**(单一时钟)。所有部件(头/躯干/双臂/双腿)从同一个 `controller.value` 派生角度,禁止一肢一个 controller 或一肢一个 `AnimationController.repeat()`。
2. **镜像肢体用数学取反,不用第二条动画**: `armLeftAngle = f(t)`, `armRightAngle = -f(t)`;`legLeft = g(t)`, `legRight = -g(t)`。相位关系由公式保证,与启动时刻无关。
3. **相位由结构保证,不靠启动对齐**: 不要依赖"两条 animation 同时 start"来对齐相位——widget 重建后会各自重启导致漂移(我们在 HTML 原型里实际踩过这个坑,修法就是共用同一条 keyframe + 几何镜像)。
4. **状态切换时 controller 从 0 重启**,起手/完成的 ×1 过渡动画天然掩盖跳变。
5. **多个小人之间不需要互相同步**;建议每个小人加 `hash(userId) % loopDuration` 的固定相位偏移,避免全房间机器人式齐步。
6. hop 等 2 倍频子运动用同一 controller 的 `Interval`/频率映射实现,不另开时钟。

## Design Tokens
全部见 `cofit_colors.dart`(基础色板 `CoFitPalette` + 语义层 `CoFitColors.dark`)。Alpha 规则:淡底 = 主色 @16%,描边 = 主色 @40%,文字层级 = gray-50 @70/50/42%,分隔线 = white @7–9%。设计参考稿顶部 #13a 有可视化 token 表。

## Files
- `design_reference.html` — 全部设计探索(自包含,浏览器直接打开;锚点 #12b、#6b、#13a 等可直达)。**定稿**: 6b 主界面、12b 牌库、13a 颜色 token;其余 turn 为过程参考。
- `cofit_colors.dart` — ThemeExtension,放入 `lib/core/theme/`。

## 建议的 Claude Code 提示词
> 阅读 design_handoff_cofit/README.md 与 design_reference.html(锚点 #12b/#6b)。先把 cofit_colors.dart 放入 lib/core/theme/ 并在 MaterialApp 注册,然后按 README 的「牌库主页(12b)」规范,在 lib/features/action/ 下实现牌库页面与动作卡片组件。所有颜色引用 CoFitColors token,不写裸色值。

# 运动记录 / 健身打卡类 App 竞品调研

> 调研日期:2026-11-20 · 性质:纯调研输入,不构成提案。是否立 change 由产品决定(走 `docs/spec/`)。
> 核心问题:**房间里没有好友在线时,靠什么让用户自己打开 CoFit、打出一张动作卡?**

---

## 0. TL;DR

1. CoFit 的「一次运动」是**一张 30–90 秒的卡**,不是一场 45 分钟的训练。竞品里以「分钟 / 训练量」为核心的指标(Strong/Hevy 的 volume、Apple 的 Exercise 分钟)直接搬过来会显得很寒酸(一周 6 min)。**计量单位应该是「出牌数 / 出牌天数」**,分钟只做辅助。
2. 单人留存最被验证的三件套是:**连续记录(streak)+ 可见的进度容器(圆环/日历)+ 适时提醒**。其余(徽章、报告、PR)是放大器。
3. 连胜要做「宽容版」:**周连胜(Hevy/Strava)或日连胜 + 冻结(Duolingo/Apple 暂停圆环)**。硬性日连胜断掉后容易直接流失。
4. CoFit 最独特的杠杆是**虚拟小人**:可以做成 Finch / 宝可梦 Sleep 式的「它在等你」,用连续出牌解锁动作 / 外观,把打卡奖励落在小人身上,而不是落在一枚抽象徽章上。
5. 现有 `users/{uid}/sessions` 能支撑**本周 / 日历热力图 / 每卡次数 / 简单日连胜**;支撑不了**长连胜、累计总数、真实时长、提前结束**。缺口主要在:只读最近 100 条、`durationSec` 记的是卡片默认时长、只记 completed、rules `hasOnly` 锁死字段。
6. 当前**没有任何推送 / 本地通知基建**,而提醒是「没人在线时把人拉回来」唯一的主动触点——这一项成本低、收益确定,建议优先。
7. UI/UX 层面(第 7 章):CoFit 打开到出牌只要 2 个手势,路径已经很短;真正的缺口是**首屏看不到任何「今天的我」**(进度、连胜都在「我的」二级页),以及**出完牌那一刻没有任何反馈**(HUD 消失、小人回待机)。推荐首屏方案见 §7.7。

---

## 1. CoFit 现状(代码事实)

### 1.1 数据:`users/{uid}/sessions/{sessionId}`

实体 [`ActionSessionRecord`](../../lib/features/action/domain/entity/action_session_record.dart),只追加,仅本人可读写:

| 字段 | 含义 | 备注 |
|---|---|---|
| `sessionId` / `userId` | 主键 / 用户 | |
| `roomId` | 在哪个房间打的卡 | **必填**:出牌只能在房间里发生 |
| `templateId` / `templateName` | 哪张卡 | 官方卡或自建卡 |
| `actionKey` | 卡片 `type` 原文 | 映射为 strength / cardio / core / flexibility |
| `motionId` | 小人动作 clip | 可选 |
| `durationSec` | 时长 | ⚠️ **= 卡片 `defaultDurationSec`,不是实际时长**([record_completed_session_usecase.dart](../../lib/features/action/usecase/record_completed_session_usecase.dart)) |
| `startedAt` / `completedAt` | 起止时间 | `Timestamp` |
| `status` | 固定 `completed` | 没有 aborted / 提前结束记录 |

补充事实:

- 官方卡 32 张,四种类型各 8 张;`defaultDurationSec` 为 30 / 45 / 60 / 90 秒(分布 4 / 12 / 14 / 2)。→ **一次 session ≈ 1 分钟**。
- 卡片模板有 `intensityBaseline.label`(如「中等」「挑战」)和 `equipment`,但**没写进 session**。
- 没有次数 / 组数 / 重量 / 主观强度(RPE)/ 心情等任何「表现」字段。
- `firestore.rules` 对 sessions 用了 `hasOnly([...])`:**加任何新字段都要先改 rules**(push main 由 CI 部署)。
- 无 Cloud Functions,也无任何汇总 / 计数文档;聚合全在客户端。
- 记录在 `OwnActionSessionNotifier.complete()` 里 fire-and-forget 落库,App 被杀由 `recoverPending` 补记。
- `pubspec` 中**没有** `firebase_messaging` / 本地通知 / `home_widget` / HealthKit 依赖。

### 1.2 页面:运动历史([workout_history_page_view.dart](../../lib/features/action/presentation/view/workout_history_page_view.dart) + [workout_history_body.dart](../../lib/features/action/presentation/widget/workout_history_body.dart))

- 入口:我的页「运动」分组(累计时长 / 完成次数)→ push。
- 顶部「本周」小结卡:次数 + 分钟 + 近 7 日微柱图。
- 下方按日期分组(今天 / 昨天 / M月d日)的记录行:类型色条、卡名、类型 · 分钟、时间。
- 只取**最近 100 条**,尾注「仅显示最近 100 条」;不展示房间信息。
- 空态:小人 + 「回到房间,打出你的第一张动作卡」+ 去房间按钮。
- AppBar 有 beta 的「AI 教练」入口(Remote Config 控制)。

**结论**:现在是一个「回顾型」页面——用户已经来了、已经练了,才会看。它没有任何**向前拉**的东西(目标、连胜、下一张卡、提醒),也藏在「我的」二级页,不在用户打开 App 的第一眼里。

---

## 2. 竞品速览

| 类别 | 产品 | 单人留存的核心抓手 | 与 CoFit 的相关度 |
|---|---|---|---|
| 力量训练日志 | **Hevy** | 周连胜 + 训练日历;实时 PR 提示;月报 / 年度回顾可分享;主屏小组件 | 高(周连胜、月报、分享卡思路) |
| | **Strong** | 极简记录 + 每个动作的历史 / PR / 曲线(本次搜索未拿到官方页面,结论来自行业通识与同类 App) | 中(PR 思路需改造) |
| | **Fitbod** | 肌群恢复热力图 → 自动生成「下一次练什么」 | 中(「下一张卡」推荐) |
| 通用活动 | **Apple 健身 / 健身圆环** | 每日三环;连续合环奖章;月度个人挑战;暂停圆环;90 天 vs 一年趋势箭头;周总结 | 高(圆环 = 每日目标容器) |
| | **Strava** | 周连胜(≥1 次 ≥60 秒的活动即算,可补传恢复);连胜贴纸可分享;年度回顾(付费) | 高(60 秒门槛几乎就是一张卡) |
| | **Keep** | 打卡卡片 + 月 / 周日历;卡片目标与卡片通知;成套主题徽章 + 获得人数;连续打卡解锁城市皮肤 | 高(打卡皮肤 ≈ 小人外观) |
| | **Nike Training Club** | 1–8 周计划;累计次数 / 分钟;次数 / 频率 / 周月连胜徽章 | 中(计划 = 牌组课表) |
| 游戏化 / 习惯 | **Duolingo** | 日连胜 + 连胜冻结 + 连胜修复活动 + 「完美周」;强提醒 | 高(机制成熟,数据最多) |
| | **Habitica** | RPG 化身;漏打卡掉血(可暂停伤害);宠物 / 坐骑;组队 Boss 战 | 中(惩罚式要慎用) |
| | **Finch** | 完成小任务 → 小鸟成长、探险、换装;小组件展示小鸟状态 | **很高**(「小人在等你」) |
| | **Streaks** | 极简每日任务 + 每任务单独提醒 + 小组件 + 读 Health 数据自动打卡 | 中(提醒与小组件) |
| | **Seven(7 分钟训练)** | 短训练 + 连胜 + 徽章(另有「三条命」类容错的宣传,未证实) | 高(同为短时长) |
| | **健身环大冒险 / Pikmin Bloom / 宝可梦 Sleep** | 运动即游戏进度;收集角色;低门槛、不惩罚 | 高(动作卡 = 技能卡的游戏化) |

---

## 3. 机制拆解:没人在线时,什么把用户拉回来

每个机制按「代表产品 / 具体做法 / 对留存的作用 / 数据前提 / CoFit 现状能否支撑」展开。

### 3.1 连续记录(Streak)

- **代表**:Duolingo(日连胜 + 冻结 + 修复)、Hevy(周连胜:每周至少 1 次)、Strava(周连胜:每周至少 1 次 ≥60 秒活动,漏传可事后补)、Apple(连续合 Move 环奖章 + 暂停圆环)、Keep(连续打卡解锁皮肤)。
- **做法要点**:
  - 连胜数字放在最显眼的位置(Hevy 放在日历顶部,还显示「距上次训练已休息 N 天」;Duolingo 放在主界面)。
  - 本周第一次完成时弹出「第 N 周连胜」(Hevy 的做法),把「完成」和「连胜 +1」绑在一起。
  - **容错**:冻结 / 暂停 / 补记 / 以周为单位,避免一次断掉就清零。
- **作用**:利用损失厌恶,把「今天练不练」变成「要不要失去 N 天」。二手资料称 Duolingo 连胜冻结让有断连风险的用户流失下降约 21%,7 日连胜用户次日回访率更高;Busuu 加连胜后次月总 session +15%(Sensor Tower)。这些数字来源都不是一手,只能当方向参考。
- **风险**:断连后可能直接放弃(Silverman & Barasch 2023 关于「断掉的连胜抑制后续参与」的研究被广泛引用,本次未核实原文)。所以要么以周为单位,要么给冻结,并且断了之后给「重新开始」的仪式而不是一个大红 0。
- **数据前提**:每天的「是否完成」+ 用户时区的自然日边界;长连胜需要服务端或汇总文档保存 `currentStreak / longestStreak / lastActiveDay`。
- **CoFit 现状**:最近 100 条能算出短期日连胜(每天 3 张卡的话只够一个月)。**长连胜与历史最长连胜需要新增汇总文档**。

### 3.2 每日 / 每周目标与进度容器(圆环)

- **代表**:Apple 三环(Move / Exercise / Stand,每天清零、目标可调);Keep「卡片目标」;Duolingo 每日 XP 目标。
- **做法**:一个**每天都会被清零的小容器**,完成即视觉闭合 + 动画。目标可调,且默认值低到第一天就能完成。
- **作用**:把模糊的「多运动」变成今天的一个具体数;「差一点就满」(目标梯度效应)是最强的当日拉回理由。Apple 这一机制被认为是 Apple Watch 用户日常留存的核心(无官方数据,但用户自述大量存在)。
- **数据前提**:今日完成量(张数 / 分钟)、用户设定的目标值。
- **CoFit 现状**:✅ 今日张数可由现有 sessions 现算;目标值需在 `users/{uid}` 加一个可选键(如 `dailyCardGoal`,profile rules 也要放行)。

### 3.3 日历 / 热力图

- **代表**:Hevy 训练日历(按年 / 多年视图,训练日标蓝)、Keep 月 / 周历、GitHub 式贡献格。
- **作用**:**把过去的坚持可视化成「不想破坏的图案」**,比单一数字更有收藏感;同时是连胜的「证据页」。
- **数据前提**:每天的完成次数。
- **CoFit 现状**:✅ 最近 100 条可画最近几周;要画「整年」需要分页读或按日汇总。

### 3.4 个人记录(PR)与进步曲线

- **代表**:Hevy / Strong / Boostcamp:最大重量、估算 1RM、单组最大量,完成一组的瞬间实时弹 PR;每个动作的历史曲线。Strava:年度最佳成绩。Apple:90 天 vs 一年的趋势箭头。
- **作用**:给老用户「变强了」的证据,是力量类 App 的长期留存核心。
- **CoFit 适配度**:**偏低**。CoFit 卡片是定时动作,没有次数 / 重量,没有「表现」可比。能做的变体:
  - 「次数类 PR」:单日最多出牌、单周最多出牌、最长连胜、某张卡累计次数里程碑(第 10 / 50 / 100 次深蹲卡)。
  - 若未来加「完成后可选填做了几个」(如 45 秒俯卧撑做了 18 个),才能有真正的表现 PR。
- **数据前提**:每张卡的历史次数;表现 PR 需要新字段 `reps`(可选)。
- **CoFit 现状**:次数类 ✅(100 条以内);长期累计需要汇总;表现 PR ❌。

### 3.5 周报 / 月报 / 年度回顾(含分享卡)

- **代表**:Hevy 月报(上月 PR、月历、肌群分布、最常做动作,免费可看,可选浅色 / 深色 / 透明背景分享)、Hevy 年度回顾(12 月初上线,含最长连胜)、Strava Year in Sport(已转付费)、Apple 周总结、Strava 连胜贴纸。
- **作用**:**一个固定节奏的「回来看看」理由**(每周一 / 每月 1 号),外加自发分享带来的拉新。年度回顾是社交平台上的传播峰值。
- **数据前提**:按周 / 月聚合;各类型占比;最常打的卡。
- **CoFit 现状**:✅ 周报可用现有数据;月报 / 年报需要突破 100 条限制。分享卡可以把**小人摆出最常打的动作**作为封面——这是别家做不出来的。

### 3.6 成就徽章 / 收集

- **代表**:Apple 奖章(连续合环 365 / 500 / 1000 天、月度挑战、限时活动)、Keep 主题成套徽章 + 显示获得人数、NTC 次数 / 频率徽章。
- **作用**:成就感 + 收集欲;限时 / 月度挑战提供「这个月的理由」。Keep 的分析认为徽章不可兑换,作用主要是炫耀与成就感,**成套主题**收集动机更强。
- **风险**:抽象徽章对很多用户无感;需要有展示场景(他人可见)才有炫耀价值。
- **数据前提**:累计次数、连胜、类型覆盖等计数器;已获得徽章列表。
- **CoFit 现状**:部分 ✅,需要汇总文档 + 徽章定义(可仿 `card_templates.json` 的 SSOT 方式)。

### 3.7 提醒通知

- **代表**:Duolingo(高频、拟人化提醒,最出名)、Streaks(每个任务单独设置「未完成才提醒」的时间)、Keep(卡片通知,提前设好打卡计划)、Apple(站立提醒、晚上「还差 X 就合环」)。
- **作用**:没人在线时**唯一的主动触点**。学术证据显示提醒能提升参与度,但对运动量的效果「温和」(MyHeart Counts 2019:提示有效但幅度不大;2026 高血压微随机试验:推送没提升短期运动量,但提升了干预参与度)。也就是说,提醒能把人带回 App,但要配合低门槛的「一张卡就行」才转化成运动。
- **好做法**:
  - **条件触发**而不是定时轰炸:「今天还没出牌」+「连胜快断了」才发。
  - 用户自选时间;一天最多一条。
  - 文案拟人化,用小人的口吻(「豆豆今天还没活动过 🥲」)。
- **数据前提**:今天是否已完成、用户偏好时间。**本地通知即可实现**,不依赖服务端。
- **CoFit 现状**:数据 ✅;**通知基建 ❌**(需新增依赖与权限申请流程)。

### 3.8 计划与「下一次练什么」

- **代表**:Fitbod(肌群恢复热力图 → 自动生成下一次训练,优先练恢复好的肌群)、NTC(1–8 周计划)、Duolingo(下一课永远只差一下点击)。
- **作用**:消除「打开后不知道做什么」的决策成本。对短时长产品尤其关键——**从打开到开始应该 ≤ 2 次点击**。
- **CoFit 适配**:「今日推荐卡」= 根据最近 7 天四种类型的分布,推一张最久没练的类型(轻量版 Fitbod);或「今日牌组」= 3 张卡的小套餐。可与 beta AI 教练结合。
- **数据前提**:最近各类型完成情况(✅)。

### 3.9 化身 / 宠物养成(情感依恋)

- **代表**:Finch(完成自我照顾小任务 → 小鸟从蛋长到成年、外出探险、换装;小组件随状态变化)、Habitica(RPG 化身,漏打卡掉血,宠物 / 坐骑)、宝可梦 Sleep(好习惯 → 收集更多宝可梦,刻意不奖励特定作息)、Pikmin Bloom(走路 → 种花、收集皮克敏,刻意低要求)、健身环大冒险(动作即攻击技能,运动点数升级)。
- **作用**:把「为了自己」变成「为了它」。Finch 的评论分析显示大量用户因为「小鸟在等我」而回来(相关性,未证明因果);第三方称 Finch D1 留存约 60%(未经官方证实)。
- **关键设计原则**(从 Finch / 宝可梦 Sleep / Pikmin 归纳):**只奖励、不惩罚**——小人不会「死」或「生病」,最多是「有点无聊 / 想动一动」;Habitica 式掉血更适合硬核用户,且本身也提供了「暂停伤害」开关。
- **CoFit 适配度**:**最高**。CoFit 已经有小人和数据驱动的动作 clip 引擎,「动作是数据不是代码」意味着**解锁新动作 / 新姿势 / 新外观的边际成本低**。
- **数据前提**:累计次数 / 连胜 → 解锁条件;已解锁列表;小人外观字段(目前 avatar 只有动作,无外观实体)。

### 3.10 主屏小组件 / 锁屏

- **代表**:Hevy 主屏小组件、Streaks 统计小组件、Finch 动态小组件(小鸟状态)、Duolingo 连胜小组件。
- **作用**:不打开 App 也能看到「今天还没练」,是推送之外的第二个被动触点,而且不打扰人。
- **数据前提**:今日状态、连胜数(需要写到 App Group 共享存储)。
- **CoFit 现状**:无相关基建;iOS 需要原生 WidgetKit extension,成本中高。

---

## 4. 对 CoFit 的可借鉴点优先级

成本粗估:S ≈ 1–3 天,M ≈ 1 周,L ≈ 2 周以上(单人 + AI agent 的节奏)。
「现有数据」列:✅ 现有 sessions 足够;🟡 短期可算,长期需要汇总;❌ 需要新字段或新基建。

### 高优先级

| # | 借鉴点 | 灵感来源 | CoFit 化做法 | 成本 | 需要的数据 / 改动 | 现有数据 |
|---|---|---|---|---|---|---|
| H1 | **今日目标「出牌环」** | Apple 圆环、Duolingo 每日目标 | 主界面(房间页)常驻一个小环:今天出了几张 / 目标几张(默认 1–3 张,可调)。满环时小人庆祝动作。 | S–M | 今日完成数(现算);`users/{uid}.dailyCardGoal`(可选键,改 profile rules) | ✅ / 目标值需新键 |
| H2 | **宽容连胜** | Hevy / Strava 周连胜、Duolingo 冻结、Apple 暂停圆环 | 推荐**以周为单位**:「每周出牌 ≥ N 天」算一周连胜(N 默认 3)。若坚持做日连胜,则每周自动给 1 次冻结。本周第一次出牌时提示「第 N 周连胜」。 | M | `currentStreak / longestStreak / lastActiveDay / freezes` 汇总;**按用户本地日期**计算(建议 session 写入时加 `localDay: 'yyyy-MM-dd'`,需改 rules) | 🟡 |
| H3 | **本地提醒(条件触发)** | Streaks、Duolingo、Keep 卡片通知 | 用户选一个时间;当天未出牌才在该时间发**一条**本地通知,文案用小人口吻;点开直达上次房间并展开手牌。连胜临断时追加一句。 | M | 偏好时间(本地或 profile);今日是否完成(本地缓存);新增本地通知依赖 + 权限引导 | ✅(数据)/ ❌(基建) |
| H4 | **小人成长 / 解锁** | Finch、健身环大冒险、Keep 打卡皮肤 | 累计出牌 / 连胜里程碑 → 解锁小人新的待机动作、庆祝动作或配色;**只奖励不惩罚**,断连时小人只是「有点无聊」。解锁表做成 SSOT JSON(仿 `card_templates.json`)。 | M–L | 累计计数器 + `unlockedItems` 列表;avatar 侧需要「外观 / 可选动作」实体(现在没有) | 🟡 |
| H5 | **运动记录页前移 + 补「向前拉」的信息** | Hevy 日历顶部连胜、Apple 健身首页 | 把「本周 / 连胜 / 今日环」的摘要放到房间页或我的页显眼处;历史页顶部加日历热力图 + 连胜;空态与「今天还没练」态给出**一键出推荐卡**。 | S–M | 现有数据 | ✅ |

### 中优先级

| # | 借鉴点 | 灵感来源 | CoFit 化做法 | 成本 | 需要的数据 / 改动 | 现有数据 |
|---|---|---|---|---|---|---|
| M1 | **今日推荐卡 / 今日三连** | Fitbod 下一次训练、Duolingo 下一课 | 按最近 7 天四种类型的分布,推最久没练的类型里的一张卡;或推一组 3 张的「今日小套餐」。可交给 AI 教练做增强版。 | S–M | 最近各类型完成情况 | ✅ |
| M2 | **周报 / 月报 + 分享卡** | Hevy 月报、Strava 连胜贴纸、Apple 周总结 | 每周一首次打开弹「上周回顾」:出牌数、天数、类型分布、最常打的卡;分享图用**小人摆出最常打的动作**做封面。月报 / 年报后做。 | M | 周聚合(现算);月 / 年需突破 100 条 | ✅(周)/ 🟡(月 / 年) |
| M3 | **次数里程碑 / 徽章** | Apple 奖章、Keep 成套徽章、NTC | 「第 10 / 50 / 100 张深蹲卡」「四种类型都打过」「连续 4 周」;优先和 H4 合并为「解锁小人东西」,避免另起一套抽象徽章。 | M | 每卡累计次数、类型覆盖 → 汇总文档 | 🟡 |
| M4 | **汇总文档(基础设施)** | Hevy / Strava 的统计页 | `users/{uid}/stats/summary`:`totalCards`、`totalActiveDays`、`currentStreak`、`longestStreak`、`lastActiveDay`、`perTemplateCount{}`、`perTypeCount{}`。写 session 时用事务 / `FieldValue.increment` 同步更新(无 Cloud Functions 的前提下由客户端维护,无排行时作弊风险可接受)。 | M | 新集合 + rules | — |
| M5 | **记录实际时长与提前结束** | 所有记录类 App | `durationSec` 改为真实经过时长(或新增 `actualDurationSec`);将来有「提前结束」入口时写 `status: aborted`,历史页只统计 completed。 | S | 新字段 + rules | ❌ |

### 低优先级

| # | 借鉴点 | 灵感来源 | 说明 | 成本 | 现有数据 |
|---|---|---|---|---|---|
| L1 | 主屏 / 锁屏小组件 | Hevy、Finch、Streaks | 显示今日环 + 连胜 + 小人状态。原生 WidgetKit,成本较高,等 H1–H3 验证有效后再做。 | L | ✅(数据) |
| L2 | 表现 PR(次数 / 主观强度) | Hevy / Strong 实时 PR | 完成后可选填「做了几个 / 感觉如何」,才有真正的 PR 与进步曲线;会增加出牌后的摩擦,和「一张卡就走」的定位有张力。 | M | ❌(需 `reps` / `rpe`) |
| L3 | 月度个人挑战 / 限时活动 | Apple 月度挑战、Keep 主题徽章 | 例如「11 月打满 20 天」,奖励限定小人外观。需要运营节奏,适合有内容产能后再做。 | M | 🟡 |
| L4 | HealthKit 写入 | Streaks 读 Health、各大健身 App | 把出牌写进 Apple 健康的体能训练,让 CoFit 的运动也能帮用户合环;需要隐私表与 PrivacyInfo 同步,且 1 分钟卡片对合环贡献有限。 | M | ✅ |
| L5 | 惩罚式机制(掉血 / 小人生病) | Habitica | **不建议**。小人是 CoFit 的情感核心,让它因为用户偷懒而受苦,容易让人产生负罪感而卸载。 | — | — |

---

## 5. 数据层缺口汇总(若立项需一并考虑)

| 缺口 | 影响的机制 | 建议 |
|---|---|---|
| 只读最近 100 条,客户端聚合 | 长连胜、累计总数、月 / 年报、徽章 | 新增汇总文档(M4),写 session 时同步增量更新 |
| `durationSec` = 卡片默认时长 | 分钟统计失真 | 写实际时长(M5);UI 主指标改为「张数 / 天数」 |
| 只记 completed | 无法区分「开始了没打完」 | 有提前结束入口时写 aborted |
| 无本地日期字段 | 跨时区 / 凌晨出牌的日界判断 | 写入时加 `localDay`(客户端时区自然日) |
| rules `hasOnly` 锁字段 | 任何新字段都要先改 rules | 字段一次性规划好,一次 rules 改动(按惯例 diff 先给用户确认,CI 部署) |
| 出牌必须在房间里(`roomId` 必填) | 提醒 / 小组件的落地页 | 提醒点开直达「上次房间」;空房间里出牌本身就是单人场景,不必另造「单人模式」 |
| 无通知基建 | 提醒 | 先做本地通知,不需要 FCM 与服务端 |
| avatar 只有动作,无外观 / 解锁实体 | 小人成长 | 新增 avatar 外观 / 解锁的数据模型(与 `docs/avatar_bean_spec.md` 对齐) |

---

## 6. 与 CoFit 特色结合的整体设想(供讨论)

> **「一张卡就算数」+「小人在等你」+「宽容的连胜」**

- 打开 App → 房间里只有自己的小人 → 小人头上 / 屏幕角落有今日出牌环(0/2)和连胜(🔥 第 5 周)。
- 底部手牌第一张是今日推荐卡(高亮)。点一下,一分钟,环闭合,小人庆祝。
- 每满一个里程碑,小人解锁一个新的庆祝动作 / 配色,下次在房间里被好友看到(社交展示价值)。
- 没来的那天晚上,只收到一条提醒:「豆豆今天还没活动过,来一张卡吗?」。
- 每周一首次打开,看到上周回顾卡,可以分享,封面是小人摆出你最常打的动作。

这样单人路径和社交路径用的是同一套东西:**单人时为了环、连胜和小人;有好友在线时,这些成就又变成可以在房间里被看到的展示。**

---

## 7. UI/UX 拆解:竞品怎样让人愿意打开 App 并记录

> 机制(第 3 章)回答「有什么」;本章回答「**放在哪、长什么样、什么时候出现**」。
>
> **方法与可信度**:依据厂商帮助页 / 功能页、设计评测(含 Pratt IXD 学生设计评析、screensdesign 截图库)、媒体评测,以及这些产品长期以来的公开界面形态。**没有实机逐屏核对**;屏幕占比是按公开截图与描述估算的量级(±10%),版本迭代可能使细节变化。能找到的出处在每节末尾和 §8 列出。

### 7.1 首屏拆解(冷启动 / 回到前台的第一眼)

| 产品 | 落地 tab | 第一眼(最大、最上) | 第二层 | 下滑 / 下一屏 | 首屏的「问题」是 |
|---|---|---|---|---|---|
| **Apple 健身(iPhone)** | Summary | **今日三环卡片**,屏幕顶部,约占首屏 1/3:三个同心圆 + 右侧三行数字(Move / Exercise / Stand 的当前值 / 目标) | 步数 / 距离、最近体能训练(最近几次)、趋势箭头 | 奖章、Fitness+ 推荐、可编辑的卡片(iOS 18 起可「编辑摘要」加卡) | 「今天离目标还差多少?」 |
| **Hevy** | Home(关注的人的训练动态) / Workout | 默认 Home 是**社交动态流**;记录入口在底部 Workout tab:顶部「+ Start Empty Workout」大按钮,下面是 Routines 卡片列表(每张卡一个「Start Routine」) | Profile 页顶部有统计与日历;日历顶部显示**周连胜**与「距上次训练已休息 N 天」 | 月报入口在 Profile > Statistics 底部 | Workout tab:「今天练哪个计划?」 |
| **Strava** | Home(关注者动态) | **动态流**:关注者的活动卡(地图缩略 + 数据 + 点赞) | 底部 tab 正中是 **Record**(固定位置,肌肉记忆) | 进度、连胜、Best Efforts 在 You tab(连胜贴纸在 Progress 区) | 「朋友最近练了什么?」——单人进度不在首屏 |
| **Keep** | 正中的「运动」tab(社区「首页」不是启动页) | 课程 / 日程 / 跑步等运动入口与推荐课程;9.0 起 tab 为「课程、日程、运动、发现、我的」 | 打卡卡片(跑步、体重、起床等)与月 / 周日历在打卡卡片页 | 发现 / 社区 | 「今天做什么运动?」(工具优先) |
| **Duolingo** | Learn(学习路径) | **顶部常驻状态条**(课程旗、🔥 连胜数、宝石、红心),约占 8%;下面是**整屏的学习路径**,当前关卡节点放大、上方带「START / 开始」气泡、轻微弹跳 | 路径就是进度本身:已完成节点为金色 / 实色,未来节点为灰 | 继续下滑是后续单元;排行榜 / 任务 / 个人页在底部 tab | 「下一课就在这,点它」 |
| **Finch** | 主页 | **小鸟所在的房间插画**占上半屏(约 40–50%),小鸟有表情和动作;插画下方是**冒险(adventure)进度条** | 下半屏是**今日目标清单**(勾选式) | 商店、旅程、社区、付费提示(被评测批评为太拥挤) | 「小鸟今天需要你完成这些」 |
| **Pikmin Bloom** | 地图 | **全屏地图场景**,自己的 Mii 化身在中央走动,皮克敏跟随(与 CoFit「全屏场景 + 小人」结构最像) | 屏幕下方的今日步数 / 按钮浮层 | 菜单里的日记 / 记录 | 「出去走走,它们会跟着你」 |

**观察**:

1. **工具型首屏问「今天」,社交型首屏问「别人」**。Apple 健身、Duolingo、Finch 的第一眼都是「今天的我」(环 / 连胜 / 宠物);Strava、Hevy 的默认首页是好友动态,单人进度要进 You / Profile 才看得到——它们的单人留存更多靠**通知、小组件与完成后的庆祝页**来补。
2. **「下一步」最好是首屏上一个具体可点的东西**:Duolingo 的当前节点 + START 气泡、Hevy 的 Start Routine、Apple iPhone 健身在 iOS 26 新增的 Workout tab(点类型旁的播放键即开始,需配对 Apple Watch)。
3. **化身型产品把「进度」和「化身状态」放在同一视线**:Finch 的小鸟和冒险进度条上下相邻;Pikmin Bloom 的化身就站在场景中央。

### 7.2 「打开 → 开始一次记录」的路径

| 产品 | 打开到开始的点击数(最短路径) | 开始按钮的位置 | 运动中界面 | 完成那一刻的反馈 |
|---|---|---|---|---|
| **Apple 健身 / Watch** | Watch:抬腕 → 点训练类型(1–2 次);iPhone(iOS 26):Workout tab → 播放键(2 次) | 训练类型列表每行右侧 | 大号计时 + 心率 + 能量 + 环的实时增量;锁屏 / 灵动岛同步 | 训练摘要页;合环时三环**闭合动画 + 烟花**、触觉反馈;获得奖章时奖章 3D 翻转动画 |
| **Hevy** | Workout tab → Start Routine(2 次),或 Quick Access 小组件「+」(1 次,从桌面) | Workout tab 顶部大按钮 / 每张 Routine 卡底部 | 计时 + 动作列表,每组一个勾选框;**勾选一组即可能实时弹 PR**;组间休息计时器进锁屏 Live Activity | 保存后进入新页面:**「第 N 次训练」序号**,本周第一次训练时显示**周连胜**,自动生成多张分享图可选 |
| **Strava** | 底部正中 Record(1 次)→ 大圆形开始按钮(1 次) | 底部 tab 正中(固定) | 大号计时 / 距离 / 配速;锁屏与灵动岛 Live Activity | 保存后看到成就(个人最佳、分段、连胜里程碑);第三方评测称会弹出「Nice work」类动画(未证实) |
| **Keep** | 运动 tab → 选课程 / 跑步 → 开始(2–3 次) | 课程详情页底部通栏「开始训练」 | 视频跟练 + 倒计时 / 跑步地图与配速 | 完成页:时长 / 消耗 + 打卡;徽章获得弹窗 |
| **Duolingo** | 点当前节点 → 「开始」(2 次) | 路径上当前节点(位置随进度移动,但永远高亮) | 题目;顶部进度条 | 课程结束是**一串连续的奖励页**:经验值结算 → **连胜 +1(火焰点燃 + 数字跳动)** → 里程碑天数(7 / 30 / 100 / 365)特制动画 → 任务进度 / 排行榜。官方博客专门讲过连胜页与里程碑动画的设计 |
| **Finch** | 点目标行的勾选框(1 次) | 首屏目标清单 | 无(记录即完成) | 勾选后获得能量,小鸟反应;能量攒满 → 小鸟出门冒险(**延迟满足**);评测建议让每次完成都有可感知的反馈 |
| **CoFit(现状)** | 打开即房间 → 点扇形手牌进入聚焦(1)→ 上滑中间卡打出(1)= **2 个手势** | 屏幕底部扇形手牌(常驻) | 自己小人做动作 + HUD 倒计时环(顶栏下) | **无**:计时到点 → HUD 消失、小人回待机;记录在后台静默落库 |

**观察**:

1. **点击数不是 CoFit 的瓶颈**(2 个手势与 Apple Watch / Strava 同一量级)。瓶颈在**「打哪张」的决策**——扇形中央那张是谁取决于上次停在哪;竞品都会把「推荐的那一个」直接放到手边(Duolingo 当前节点、Hevy 计划里下一个 Routine)。
2. **完成那一刻是最强的强化点**,头部产品都把「连胜 +1」「第 N 次」「PR」**放进完成流程里**,而不是让用户自己去历史页发现。Duolingo 团队的说法是:连胜状态的变化发生在课程内部,而不是一条通知或一个等待被发现的角标。CoFit 目前在这一刻是空白。
3. 运动中界面的共识:**一个巨大的计时 / 进度 + 一个结束 / 下一步**。CoFit 的 HUD 已符合;短卡(30–90 秒)不需要锁屏 Live Activity。

### 7.3 进度可视化:形态、位置与「差一点就满」

| 形态 | 代表 | 位置 / 常驻性 | 「差一点就满」怎么表达 |
|---|---|---|---|
| **同心圆环** | Apple 健身 | Summary 顶部常驻;表盘复杂功能;小组件 | 未满部分是同色低透明度轨道,剩余弧长一眼可见;超过 100% 时圆环**继续绕圈并叠出阴影**(奖励超额);合环时闭合动画 + 烟花 + 触觉;晚间推送「还差一点就能合环」 |
| **火焰 + 数字** | Duolingo、Strava 连胜贴纸 | 首屏顶部状态条常驻(Duolingo) | 今天未完成时火焰为**灰色 / 熄灭态**,完成后点燃变橙;连胜小组件里吉祥物**随时间推移越来越慌张**(官方博客描述) |
| **路径 / 节点** | Duolingo | 首屏主体 | 当前节点放大 + 弹跳 + 气泡;单元内进度环围绕节点 |
| **日历 / 热力格** | Hevy、Keep、GitHub 式 | 二级页(Profile / 打卡卡片) | 训练日高亮;Hevy 在日历顶部写「已休息 N 天」——用**反向数字**制造轻微紧迫感 |
| **进度条** | Finch 冒险条、Duolingo 课程内 | Finch 首屏紧贴宠物下方 | 条快满时,完成一个小目标就能触发冒险(延迟奖励);进度条与角色**物理相邻**,让「进度」读作「它的状态」 |
| **化身状态** | Finch、Pikmin Bloom、Duolingo 小组件 | 首屏主体 / 小组件 | 情绪表达(开心 / 无聊 / 着急)而非数字;Finch 宠物「不在时也在生活」 |
| **周微柱图** | Apple 周总结、CoFit 历史页 | 二级页 | 当天柱高亮,其余降透明度(CoFit 已有) |

**观察**:有效的进度可视化都满足三点——**常驻首屏(或小组件)**、**未完成态本身就有表情**(灰火焰 / 空轨道 / 着急的吉祥物),以及**完成态有一次性的高潮动画**。CoFit 历史页的 7 日微柱只满足「二级页可查」。

### 7.4 运动之外的入口:通知、小组件、锁屏、灵动岛

| 产品 | 通知(点开落在哪) | 主屏 / 锁屏小组件 | Live Activity / 灵动岛 |
|---|---|---|---|
| **Apple** | 接近一天结束时提醒合环、站立提醒、好友竞赛动态;点开进入健身 App / Watch 的活动页 | 健身圆环小组件(主屏与锁屏) | 体能训练进行中显示计时与数据 |
| **Duolingo** | 用户自定时间 + 按个人回应时间建模的提醒;文案由不同角色发出,越晚越「着急」,22 点左右「最后机会」;点开回到 App(本次未找到确认直达课程的资料) | 2022 年起推出连胜小组件:**吉祥物表情随连胜状态变化**,点一下即进 App 做一课;锁屏版是时间下方的小猫头鹰 + 连胜数 | 2026 年初曾被报道在灵动岛 / Live Activity 投放订阅广告,违反 Apple 设计指南后疑似撤下——**反面案例** |
| **Hevy** | 关注者互动;实时 PR 发生在 App 内 | **Quick Access 小组件**:点「+」直接开始一次训练;另有统计类小组件 | 训练中锁屏 Live Activity:当前动作、下一组、**组间休息倒计时**,可 ±15 秒或跳过 |
| **Strava** | 社交互动(点赞 / 评论)为主 | 有(进度类) | 开始记录即出现在锁屏,支持的机型同时显示在灵动岛 |
| **Finch** | 目标提醒,小鸟口吻 | **动态小组件**:小鸟状态、冒险进度;评测认为它围绕「陪伴感」设计——你不在时宠物也在生活 | — |
| **Keep** | 打卡卡片通知(提前设好打卡计划) | 打卡类小组件 | 跑步中 Live Activity(常见做法) |
| **CoFit(现状)** | **无**(尚无通知基建) | 无 | 无(且 30–90 秒的卡不太需要) |

**观察**:

1. 通知点开后的落点决定转化:最好的做法是**落在「已经准备好的那一步」**——Hevy 小组件「+」直接开训、Duolingo 小组件点开直接做一课。落在首页再让人找,就浪费了这一次唤起。
2. 对短时长产品,**小组件价值 > Live Activity**:Live Activity 服务的是「运动中」,而 CoFit 的运动只有 1 分钟;小组件服务的是「还没开始」,正是单人留存要解决的问题。
3. 吉祥物 / 化身在小组件里**用表情传达状态**,比数字更容易被注意且不显得说教(Duolingo、Finch)。CoFit 的豆豆小人天然适合。

### 7.5 可复用的 UI/UX 原则

1. **首屏回答「今天的我怎么样」**:一个常驻的今日进度(环 / 条 / 化身状态)+ 连胜,不需要点击就能看到。
2. **「下一步」是一个具体的东西,而且已经放在手边**:推荐卡 / 当前节点 / 下一个 Routine,而不是一个泛泛的「开始」。
3. **从唤起到开始 ≤ 2 次操作**,通知与小组件**直达**这一步。
4. **完成那一刻要有高潮**:进度闭合动画 + 数字跳动(第 N 张 / 连胜 +1)+ 触觉;里程碑日加一张特制庆祝页;**这一刻顺手给出分享**。
5. **未完成态要有表情但不惩罚**:灰火焰、空轨道、化身「有点无聊」——提示而不羞辱。
6. **进度与角色放在同一视线**(Finch):让「我的进度」读作「它的状态」。
7. **个人进度不随场景切换变化**:放在固定的外壳层,而不是可以滑走的内容里。
8. **回顾放在第二层**:首屏只露摘要(本周 3/5 天),点开 / 下拉才是日历、历史、月报;特殊时刻(周一回顾、里程碑)才短暂占据首屏。
9. **克制**:Finch 被批评首页拥挤;Duolingo 因在灵动岛放广告被批评。只放与「今天出一张卡」直接相关的东西。

### 7.6 CoFit 现状对照

依据 [room_main_view.dart](../../lib/features/room/presentation/view/room_main_view.dart)(#6b 定稿)、[docs/README.md](../README.md) §1–2、[workout_history_page_view.dart](../../lib/features/action/presentation/view/workout_history_page_view.dart):

| 层 | 现状 | 对照原则 |
|---|---|---|
| 首屏 | 全屏沉浸场景:好友小人漂浮(状态色光圈:运动中 lime / 暂停 amber / 挂机 gray);左上悬浮 dock(收起态只显示当前页图标);顶栏「房间名 · X 人 · Y 人运动中」+ 右侧「房间 n/m」;左右滑切换房间 | ✅ 社交状态一眼可见;❌ **没有任何「今天的我」**(原则 1) |
| 下一步 | 底部扇形手牌常驻;牌组 chip 在左下 | ✅ 入口常驻;🟡 中央卡不是「推荐」,只是上次停留的位置(原则 2) |
| 开始路径 | 点扇形 → 聚焦 → 上滑中央卡 = 2 个手势 | ✅ 原则 3 |
| 运动中 | 自己的小人播放动作 + 顶栏下 HUD(倒计时进度环) | ✅ |
| 完成时 | HUD 消失、小人回待机;记录静默落库;无动画、无触觉、无数字 | ❌ **最大缺口**(原则 4) |
| 进度 | 只在「我的 → 运动 → 运动历史」二级页:本周次数 / 分钟 + 7 日微柱 | ❌ 原则 1、5、6 |
| 场外入口 | 无通知、无小组件 | ❌ 原则 3 的「直达」无从谈起 |
| 一人房间 | 场景里只有自己的小人,周围空白 | 机会:空白正好留给「自己的状态」 |

### 7.7 首屏方案(供比较)

三个方案共享的前提(与方案无关,都建议做):

- 今日进度 / 连胜挂在**固定外壳层**(与 dock、顶栏同层),**不放进左右滑的房间 PageView 里**——它是「我」的,不随房间变。
- 扇形手牌**打开时把推荐卡放在中央**并加一个小标记(如「今日推荐」淡底徽章)。
- **完成反馈**:计时到点 → 自己小人播放一次庆祝动作 + 进度指示闭合 / 数字 +1 + 轻触觉;当天第一张 / 达成今日目标 / 连胜里程碑时追加一个**自动消失的 toast 或小卡**(「第 5 周连胜 🔥」),不阻断场景。
- 通知 / 小组件点开 → 上次聚焦的房间 + **直接进入手牌聚焦态**,推荐卡居中(深链已有 `cofit://room/<roomId>` 格式,具体参数另议)。

> ⚠️ 以下都会改变 #6b 定稿的首屏构成,按 CLAUDE.md 的 UI 铁律属于**设计决策,需要用户拍板**后再走 `ui-implementation` / `design-tokens` 流程;本节只给选项,不定稿。

#### 方案 A:顶栏「今日胶囊」(最小改动)

```
┌────────────────────────────────────┐
│ [dock] 房间名·3人·1运动中   房间1/2 │
│        [◔ 1/2 今日] [🔥 第3周]      │ ← 新增:顶栏下一行的两枚小胶囊(外壳层)
│                                    │
│        (好友小人漂浮场景)           │
│              🙂(我)               │
│                                    │
│   [牌组 chip]   ╭扇形手牌╮          │
└────────────────────────────────────┘
```

- **今日进度**:顶栏下方的小进度环 + 「1/2」;**连胜**:相邻的火焰胶囊(未完成今日时为灰)。
- **成果回顾**:点胶囊 → 底部抽屉「我的今天」:今日环、本周日历条、最近记录、「查看全部」→ 运动历史页。
- **开始入口**:不变(扇形手牌 + 推荐卡居中)。
- **取舍**:✅ 改动最小,和 #6b 的悬浮层语言一致,不挡场景;✅ 多房间切换时位置固定。❌ 视觉权重低,和顶栏、连接提示条、HUD 抢同一块区域(运动中要让位);❌ 「进度」与小人分离,没用上 CoFit 最独特的资产。

#### 方案 B:「我的小人就是进度」(化身即状态,Finch 式)

```
┌────────────────────────────────────┐
│ [dock] 房间名·3人·1运动中   房间1/2 │
│                                    │
│     (好友)        (好友)           │
│              ◜🙂◝   ← 我:脚下光环随今日出牌填满
│              🔥3     ← 小人身旁的连胜小标
│                                    │
│   [牌组 chip]   ╭扇形手牌╮          │
└────────────────────────────────────┘
```

- **今日进度**:自己小人脚下的**地面光环 / 底座**按今日张数逐段填满(与好友头顶的状态色光圈在形态上区分开,避免和「运动中 / 挂机」的颜色语义冲突);未出牌时小人偶尔做「无聊 / 伸懒腰」待机动作。
- **连胜**:小人旁的小火焰 + 数字。
- **成果回顾**:点自己的小人 → 「我的今天」抽屉(同方案 A)。
- **开始入口**:不变;小人「无聊」时可以朝手牌方向做一个邀请手势。
- **取舍**:✅ 最有 CoFit 辨识度,首屏不加任何 UI 框;✅ 一人房间时空白自然被「自己」填满;✅ 与第 4 章 H4「小人成长 / 解锁」同一套资产。❌ 需要新的小人渲染层(光环 / 底座分段、新待机 clip),成本最高;❌ 可发现性弱,数字不够直观(需要首次引导);❌ 自己的小人位置随场景布局漂浮,好友多时可能被遮挡。

#### 方案 C:「今日面板」下拉卡(信息最全)

```
┌────────────────────────────────────┐
│ [dock] 房间名·3人·1运动中   房间1/2 │
│ ┌────────────────────────────────┐ │
│ │ 今天 ◔ 1/2张   🔥 第3周          │ │ ← 冷启动 / 当天未达标时展开的面板
│ │ 一二三四五六日 ●●○●○○○          │ │
│ │ [来一张:深蹲 60s  ▶]            │ │
│ └────────────────────────────────┘ │
│        (场景,被压缩到下半部)        │
│   [牌组 chip]   ╭扇形手牌╮          │
└────────────────────────────────────┘
```

- **今日进度 + 连胜 + 本周日历条 + 一键开始推荐卡**集中在顶部面板;打出一张后或上滑后**收起为方案 A 的胶囊**。
- **取舍**:✅ 信息最完整,对「打开后不知道干嘛」的新用户最友好,和 Apple 健身 Summary / Duolingo 顶部状态条的心智一致;✅ 「来一张」按钮让开始路径变成 1 次点击。❌ 与 #6b「打开即满屏看到好友活跃状态」的定位直接冲突,好友场景被压缩;❌ 每次打开都要先收起它,对已养成习惯的用户是摩擦;❌ 和扇形手牌形成两个「开始入口」,需要说清主次。

#### 推荐:A 为底 + B 的反馈与表情 + C 只在特殊时刻出现

- **常驻**用方案 A 的两枚胶囊(今日环 + 连胜),位置固定在外壳层,成本 S–M,马上能验证「首屏看到今天」是否提升出牌率。
- **完成反馈和未完成态**借方案 B:庆祝动作、无聊待机、胶囊闭合动画都落在自己的小人上——不必先做脚下光环,先用动作 clip(数据驱动,边际成本低)表达状态。
- **方案 C 的面板只在特殊时刻**出现:每周一首次打开(上周回顾)、连胜里程碑、断连后第一次回来(「重新开始」而不是红色的 0),展示一次后收起为胶囊。
- 验证数据后,再决定是否把常驻进度升级为方案 B 的「小人脚下光环」。

---

## 8. 参考来源

> 多数为厂商帮助页 / 功能页与二手分析,留存数字大多无法追溯到一手数据,文中已标注;仅作方向参考。

**力量训练日志**
- Hevy:[日历与连胜](https://help.hevyapp.com/hc/en-us/articles/35380117933207-Track-Your-Workout-Consistency-with-the-Calendar-and-Streak-Features) · [实时 PR](https://www.hevyapp.com/features/live-pr/) · [月报](https://www.hevyapp.com/features/monthly-report/) · [年度回顾](https://help.hevyapp.com/hc/en-us/articles/35700454899991-Discover-Your-Hevy-Training-Stats-with-the-Yearly-Review) · [主屏小组件](https://www.hevyapp.com/features/home-screen-widgets/) · [分享](https://www.hevyapp.com/features/shareable/)
- Boostcamp:[个人记录](https://www.boostcamp.app/features/personal-records)
- Fitbod:[如何生成训练](https://help.fitbod.me/hc/en-us/articles/360004429814-How-Fitbod-Creates-Your-Workout) · [肌肉恢复](https://help.fitbod.me/hc/en-us/articles/360006269014-Muscle-Recovery)

**通用活动**
- Apple:[趋势(90 天 vs 一年)](https://www.macworld.com/article/3429077/ios-13-and-apple-watch-activity-trends-give-you-the-big-picture.html) · [奖章与挑战](https://www.wareable.com/apple/how-to-view-earn-apple-watch-awards-challenges-badges-achievements) · [连续合环 500 天体验](https://www.macworld.com/article/3179972/i-closed-my-rings-for-500-days-by-cracking-the-apple-watch-code.html) · [多日奖章更新](https://9to5mac.com/2024/12/11/apple-watch-just-gained-a-helpful-new-feature-for-inspiring-you-to-stay-active/)
- Strava:[周连胜说明](https://support.strava.com/hc/en-us/articles/36553427481997-Streaks-on-Strava) · [年度最佳成绩与连胜贴纸](https://www.t3.com/active/strava-annual-best-efforts-rollout-0426)
- Keep:[App Store 介绍](https://apps.apple.com/app/id1475058682) · [徽章体系分析(人人都是产品经理)](https://www.woshipm.com/evaluating/1677058.html)
- Nike Training Club:[App Store](https://apps.apple.com/app/301521403) · [使用介绍](https://www.makeuseof.com/how-use-nike-training-club-app-next-level-fitness/)

**游戏化 / 习惯**
- Duolingo:[Sensor Tower:连胜对参与度的影响](https://sensortower.com/blog/duolingo-streak-feature-app-engagement-growth) · [产品分析(含冻结数据,来源未证实)](https://www.blitzllama.com/blog/duolingo-product-management-lessons) · [留存实验汇总](https://experiments.lazyweb.com/research/duolingo-retention-experiments)
- 连胜的风险:[Yu-kai Chou:连胜设计与倦怠](https://yukaichou.com/gamification-analysis/streak-design-gamification-motivation-burnout/)
- Habitica:[FAQ](https://habitica.fandom.com/wiki/FAQ) · [死亡机制](https://habitica.fandom.com/wiki/Death)
- Finch:[小组件驱动留存分析](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl) · [评论与情感依恋分析](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/)
- Streaks:[App Store](https://apps.apple.com/us/app/streaks/id963034692) · [The Sweet Setup 评测](https://thesweetsetup.com/apps/best-habit-tracking-app-ios/)
- Seven:[TechRadar 评测](https://www.techradar.com/computing/websites-apps/this-gym-beating-workouts-app-finally-got-me-exercising-daily)
- 宝可梦 Sleep / Pikmin Bloom:[Pokémon 公司开发访谈](https://corporate.pokemon.co.jp/en/topics/detail/110.html) · [Fast Company:Pikmin Bloom](https://www.fastcompany.com/90689136/nintendo-niantic-pikmin-bloom)
- 健身环大冒险:[Wikipedia](https://en.wikipedia.org/wiki/Ring_Fit_Adventure)

**提醒的研究证据**
- [60 岁以上人群提醒 RCT(2020)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7318722/) · [HeartSteps 微随机试验](https://mhealth.jmir.org/2019/9/e12956) · [MyHeart Counts 数字试验](https://www.sciencedaily.com/releases/2019/10/191009225613.htm) · [高血压推送微随机试验(2026)](https://www.jmir.org/2026/1/e78218/authors)

**UI/UX 拆解(第 7 章)**
- Apple 健身:[iOS 26 健身 App 四个 tab 与 Summary](https://afb.org/blog/entry/ios-26-mainstream-features) · [iOS 14 健身 App 的 Summary 结构(MacStories)](https://www.macstories.net/stories/the-new-fitness-app-in-ios-14/) · [自定义 Summary(iOS 18)](https://www.idropnews.com/?p=227225) · [iOS 26 Workout tab 与 Workout Buddy(Engadget)](https://www.engadget.com/wearables/how-to-use-workout-buddy-with-apple-watch-and-ios-26-130000922.html) · [Close Your Rings](https://www.apple.com/watch/close-your-rings/)
- Hevy:[开始空白训练](https://www.hevyapp.com/features/start-empty-workout/) · [训练 vs Routine](https://help.hevyapp.com/hc/en-us/articles/33703513582871-Workouts-vs-Routines-in-Hevy-What-They-Mean-and-How-to-Use-Them) · [如何记录一次训练](https://help.hevyapp.com/hc/en-us/articles/35361530647959-How-to-Log-a-Workout-in-the-Hevy-App-Step-by-Step-Guide) · [Live Activity](https://help.hevyapp.com/hc/en-us/articles/35649846517399-How-to-Use-Hevy-s-Live-Activity-on-iOS-and-Android) · [截图库(screensdesign)](https://screensdesign.com/apps/hevy-workout-tracker-gym-log/?vs=212387)
- Strava:[导航改版 Home / Maps / Record / Groups / You(BikeRumor)](https://bikerumor.com/strava-redesigns-their-app-navigation-to-make-it-easier-to-track-rides-find-friends) · [Live Activities](https://support.strava.com/en-us/articles/15401559-strava-live-activities-on-ios) · [Strava iPhone 设计评析(Pratt IXD)](https://ixd.prattsi.org/?p=33047)
- Keep:[Keep 9.0 改版分析(人人都是产品经理)](https://www.woshipm.com/evaluating/6385599.html) · [Keep 回归工具属性(界面新闻)](https://m.jiemian.com/article/10973065.html)
- Duolingo:[新首页(学习路径)设计](https://blog.duolingo.com/new-duolingo-home-screen-design/) · [连胜里程碑动画设计](https://blog.duolingo.com/streak-milestone-design-animation) · [连胜如何养成习惯](https://blog.duolingo.com/how-duolingo-streak-builds-habit) · [小组件设计](https://blog.duolingo.com/widget-feature/) · [灵动岛广告争议(MacRumors 论坛)](https://forums.macrumors.com/threads/duolingo-used-iphones-dynamic-island-to-display-ads-violating-apple-design-guidelines.2475501) · [连胜机制拆解(Deconstructor of Fun)](https://duolingo.deconstructoroffun.com/mechanics/streaks) · [859 个连胜设计研究(Mobbin)](https://mobbin.com/blog/streaks-are-about-losing-a-study-of-859-streak-designs)
- Finch:[设计评析 2025(Pratt IXD)](https://ixd.prattsi.org/2025/09/design-critique-finch-ios-app-2/) · [设计评析 2024(Pratt IXD)](https://ixd.prattsi.org/2024/09/design-critique-finch-ios-app) · [截图与流程(screensdesign)](https://screensdesign.com/showcase/finch-self-care-pet)
- Pikmin Bloom:[Fast Company](https://www.fastcompany.com/90689136/nintendo-niantic-pikmin-bloom)

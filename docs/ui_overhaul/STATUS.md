# UI 大改造 — 进度与决议追踪

> 每次完成一块 UI 工作后更新本文件(ui-implementation skill 第 7 步)。
> 设计规范见 [docs/README.md](../README.md),视觉稿见 [design_reference.html](../design_reference.html)。

## 阶段计划(2026-08-01 与用户确认)

P0 主题基建 → P1 动作卡片组件 → P2 牌库主页 → P3 悬浮 dock + 导航骨架 → P4 房间主界面 → P5 「我的」页 + 收尾。
范围外:Rive 动画引擎(小人用占位形象)、Firestore 结构大改、Live Activities、好友系统真实后端。

## 屏幕进度

| 屏幕/组件 | 设计锚点 | 状态 | 备注 |
|---|---|---|---|
| 主题注册(CoFitColors → MaterialApp) | #13a | ✅ 完成 | P0:cofit_theme.dart(深色 ThemeData + Space Grotesk via google_fonts)、cofit_dimens.dart、CoFitOpacities;main.dart 已接入 |
| 动作卡片组件(全 App 复用) | #12b 卡片解剖 | ✅ 完成 | P1:`action/presentation/widget/action_card.dart`(selected/editing/onShare/onRemove 四态)+ `action_type_style.dart`(类型→文案/图标/色);G1/G2 已落地 entity + firebase repository;widget/单元测试已补 |
| 房间主界面(漂浮气泡 + 扇形手牌) | #6b, #5d, #4a | ⬜ 未开始 | |
| 悬浮 dock(全局导航) | #t9 / #12b 左上 | ⬜ 未开始 | |
| 牌库主页(牌库/我的卡组 tab) | #12b | ✅ 完成 | P2:`action/presentation/view/card_library_page.dart` + `widget/library_tab_body.dart`/`deck_list_body.dart`/`library_segmented_control.dart`;**导航入口待 P3 dock 接线**;创建/详情/分享/加卡为 stub |
| 「我的」/个人设置 | #t10 | ⬜ 未开始 | ⚠ 10a/10b 均未定稿,实现前必须先问用户选哪版 |

状态图例:⬜ 未开始 / 🟡 进行中 / ✅ 完成 / ⏸ 等决议

## 数据缺口(设计 ↔ 现有数据模型不匹配,处理前须问用户)

| # | 缺口 | 现状 | 设计需要 | 决议 |
|---|---|---|---|---|
| G1 | 动作类型枚举 | `ActionTemplateCard.type` 为自由 String,Firestore 直读 | strength/cardio/core/flexibility 四类,决定类型色条 | ✅ domain 加 `ActionType` 枚举,repository 映射,未知值 fallback 默认类型并保留原文;Firestore 不动(2026-08-01) |
| G2 | 卡片来源 | 无字段 | 官方/自建/好友分享 徽章 | ✅ entity 加 `ActionSource` 枚举字段(official/custom/friendShared),Firestore 无值默认 official(2026-08-01) |
| G3 | 牌组(deck) | 无 entity | 牌库页「我的卡组」tab、扇形手牌的「当前卡组」 | ✅ DRAFT `ActionDeck{id, name, cardIds}`(有序、允许重复,张数/时长/配色现算)+ repository 层 `activeDeckId`;in-memory stub 用真实卡 id 播种(2026-08-01) |
| G4 | 好友/分享 | `social` feature 为空目录 | 卡片分享给好友、好友分享来源 | 🟡 UI 侧按 stub 处理(分享 → SnackBar);真实分享流程与 social 数据模型仍待定 |

## Stub 登记表(预估数据模型的临时实现)

| feature | draft entity | in-memory repo | 页面 | 转正待办 |
|---|---|---|---|---|
| action(牌组) | `domain/entity/action_deck.dart` | `data/in_memory_action_deck_repository.dart`(用已加载模板卡播种 3 套示例) | 牌库页「我的卡组」tab | 接 Firestore `users/{uid}/decks` + `activeDeckId`;牌组增删改/排序 |
| action(创建卡片) | — | — | 牌库页横幅 → SnackBar | 12a 创建表单(名称/类型/时长/图标)设计定稿后实现 |
| action(卡片详情/加入卡组) | — | — | 点卡 → SnackBar | 详情/加组弹层设计未出 |
| action(分享给好友) | — | — | 自建卡 ↗ → SnackBar | 依赖 social feature(G4) |

## 决议记录

| 日期 | 问题 | 决议 |
|---|---|---|
| 2026-08-01 | 阶段顺序 | 按 P0→P5 组件先行顺序推进 |
| 2026-08-01 | G1 类型枚举 | domain 加枚举 + repository 映射,详见上表 |
| 2026-08-01 | G2 来源字段 | entity 加 source 枚举字段,详见上表 |
| 2026-08-01 | 卡片底行布局(README §4 与 #12b mock 冲突) | 按 #12b 定稿 mock:右上=来源徽章(官方灰/好友蓝,自建卡=分享↗),底行=时长(自建卡追加「· 自建」);README §4 的「底行 类型·来源」写法作废 |
| 2026-08-01 | 事件 actionKey | entity.type 改枚举后,Ably 事件 actionKey 沿用 `rawType`(Firestore 原文),线上行为不变 |
| 2026-08-01 | G3 deck 模型 | entity 只存最小事实 `{id, name, cardIds}`(有序 List、允许重复);张数/总时长/缩略配色由关联卡现算;`activeDeckId` 是用户级偏好,放 repository 接口不放 entity;不加 userId(归属由存储路径表达)、暂缓 createdAt/lastUsedAt |
| 2026-08-01 | 「我的卡组」tab 视觉 | #12b 定稿未画该 tab,按 README §3 描述 + #11b 过程稿实现(行式总览 + 就地展开);若后续出定稿再校 |

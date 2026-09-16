# UI 大改造 — 进度与决议追踪

> 每次完成一块 UI 工作后更新本文件(ui-implementation skill 第 7 步)。
> 设计规范见 [docs/README.md](../README.md),视觉稿见 [design_reference.html](../design_reference.html)。

## 阶段计划(2026-08-01 与用户确认)

P0 主题基建 → P1 动作卡片组件 → P2 牌库主页 → P3 悬浮 dock + 导航骨架 → P4 房间主界面 → P5 「我的」页 + 收尾。**全部完成(2026-08-01)**,剩余润色/转正项见各行备注与 Stub 登记表。
范围外:Rive 动画引擎(小人用占位形象)、Firestore 结构大改、Live Activities、好友系统真实后端。

## 屏幕进度

| 屏幕/组件 | 设计锚点 | 状态 | 备注 |
|---|---|---|---|
| 主题注册(CoFitColors → MaterialApp) | #13a | ✅ 完成 | P0:cofit_theme.dart(深色 ThemeData + Space Grotesk via google_fonts)、cofit_dimens.dart、CoFitOpacities;main.dart 已接入 |
| 动作卡片组件(全 App 复用) | #12b 卡片解剖 | ✅ 完成 | P1:`action/presentation/widget/action_card.dart`(selected/editing/onShare/onRemove 四态)+ `action_type_style.dart`(类型→文案/图标/色);G1/G2 已落地 entity + firebase repository;widget/单元测试已补 |
| 房间主界面(漂浮气泡 + 扇形手牌) | #6b, #5d, #4a | ✅ 完成 | P4:`room/presentation/view/room_main_view.dart` + `widget/room_scene.dart`/`avatar_bubble.dart`/`room_top_bar.dart` + `action/presentation/widget/card_fan.dart`/`deck_switcher.dart`;PageView 左右滑切房间(复用 roomBrowserProvider 多房间流);dock「浏览」槽位已回收,浏览房间从右上「+」压栈进入。**未做的润色**:能量爆发粒子、打出飞卡动画、HUD 倒计时本地滴答 |
| 悬浮 dock(全局导航) | #t9 / #12b 左上 | ✅ 完成 | P3:`core/widget/floating_dock.dart`(9a 固定槽位 + 5s 自动收起)+ `core/navigation/app_shell.dart`;登录后 AuthGatePage → AppShell,旧 `AuthHomePage`(Material 底部导航)已删除;牌库页已接入真实导航 |
| 牌库主页(牌库/我的卡组 tab) | #12b | ✅ 完成 | P2:`action/presentation/view/card_library_page.dart` + `widget/library_tab_body.dart`/`deck_list_body.dart`/`library_segmented_control.dart`;**导航入口待 P3 dock 接线**;创建/详情/分享/加卡为 stub |
| 牌组管理(列表/详情/加卡) | #15a/b/c | ✅ 完成 | 阶段三(2026-08-12):`deck_list_body.dart` 重写(使用中徽章/空组引导/⋯菜单/虚线新建)+ `deck_detail_page_view.dart`(改名/拖动排序/按索引移除/第N次)+ `deck_add_cards_sheet_view.dart`(筛选+多选×N,小屏 3→2 列)+ 共用命名 dialog |
| 创建/删除自建卡 | #16a/b | ✅ 完成 | `custom_card_form_sheet_view.dart`(实时预览/类型四选/时长档位+自定义/强度 chips;创建与编辑共用)+ `card_detail_sheet_view.dart`(大预览/已加入N组/加入牌组/编辑/删除,官方卡无编辑删除区)。**未做润色**:创建成功后滚动定位到新卡 + 1.2s 外发光(现为 toast「已创建」) |
| 房间管理·房主侧 | #17a/b | ✅ 完成 | `room_actions_sheet.dart` 房主版(房主徽章/编辑/邀请/解散红字)+ `room_edit_sheet_view.dart` + `dissolve_room_dialog.dart`(输入房间名解锁);成员端进入已解散房间 → toast+懒清理(在我的房间页) |
| 运动历史 | #18a/b | ✅ 完成 | `workout_history_page_view.dart` + `workout_history_body.dart`(本周小结+7日微柱现算/日期分组/100条尾注)+ bob 小人空态;我的页运动行点击进入 |
| 登录页(正式视觉) | #19a | ✅ 完成 | 品牌区(`login_brand_block.dart`:bob 小人+斜插卡)+ 径向环境光 + 新 slogan;**Apple / Google / 邮箱三种登录全部上线**(2026-09-17 真机验证) |
| Onboarding(正式视觉) | #19b | ✅ 完成 | 「你的小人已就位」+ 发光圆环 + 「形象定制 即将上线」角标(点按 toast)+ 空名禁用 CTA |
| 邀请预览(正式视觉) | #20a | ✅ 完成 | eyebrow + 房卡(剪影氛围区,静态装饰不谎报人数)+ 失效态「知道了」+ 空描述收起 |
| 建房成功态(正式视觉) | #20b | ✅ 完成 | ✓ burst 徽章(burstRing token)+ 链接卡(等宽截断+复制)+ 主 CTA 分享 + 「先进房间看看」 |
| 我的房间(房间浏览重做) | #20c | ✅ 完成 | `my_rooms_page_view.dart` 替代旧 RoomBrowsePage/RoomCommunityPage(均已删):presence 副行(呼吸绿点)+ 当前/进入 + 房主徽章 + 手输 ID 降级页尾 + 空态双 CTA + 已解散房间懒清理 |
| 「我的」/个人设置 | #t10 → 10a | ✅ 完成 | P5:用户选定 10a(形象优先),内容收敛到已实现功能(hero + 房间/牌组/卡牌统计 + 邮箱 + 退出登录);10a 的 累计时长/打卡/通知隐私开关 未做(功能不存在);`auth/presentation/view/my_page_view.dart` + `widget/my_page_body.dart` |

状态图例:⬜ 未开始 / 🟡 进行中 / ✅ 完成 / ⏸ 等决议

## 数据缺口(设计 ↔ 现有数据模型不匹配,处理前须问用户)

| # | 缺口 | 现状 | 设计需要 | 决议 |
|---|---|---|---|---|
| G1 | 动作类型枚举 | `ActionTemplateCard.type` 为自由 String,Firestore 直读 | strength/cardio/core/flexibility 四类,决定类型色条 | ✅ domain 加 `ActionType` 枚举,repository 映射,未知值 fallback 默认类型并保留原文;Firestore 不动(2026-08-01) |
| G2 | 卡片来源 | 无字段 | 官方/自建/好友分享 徽章 | ✅ entity 加 `ActionSource` 枚举字段(official/custom/friendShared),Firestore 无值默认 official(2026-08-01) |
| G3 | 牌组(deck) | 无 entity | 牌库页「我的卡组」tab、扇形手牌的「当前卡组」 | ✅ DRAFT `ActionDeck{id, name, cardIds}`(有序、允许重复,张数/时长/配色现算)+ repository 层 `activeDeckId`;in-memory stub 用真实卡 id 播种(2026-08-01) |
| G4 | 好友/分享 | `social` feature 为空目录 | 卡片分享给好友、好友分享来源 | 🟡 UI 侧按 stub 处理(分享 → SnackBar);真实分享流程与 social 数据模型仍待定 |
| G5 | 成员昵称/头像 | presence 只有 userId/clientId,库中无昵称字段 | 气泡下方显示昵称(如「小李」) | ✅ **已接线**(2026-08-10):决议=昵称随 presence data 下发(零额外读库);`RoomPresenceMember.nickname` + `RoomScene.displayName` 优先昵称,无昵称(旧客户端/未加载)回退 uid 前 6 位。头像仍占位 |

## Stub 登记表(预估数据模型的临时实现)

| feature | 现状 | 仍缺什么 |
|---|---|---|
| action(分享给好友) | 自建卡 ↗ → SnackBar | 依赖 social feature(G4 好友系统未实现) |
| action(创建成功定位) | 创建后仅 toast「已创建」 | #16a 附注的「滚动到新卡 + 1.2s 外发光」润色未做(token 已备:`motion.createGlow`) |
| room(小人形象) | `avatar_bubble.dart` 占位几何小人 | 范围外决议:接 Rive 时替换 `_PlaceholderFigure` |
| avatar(编辑形象) | 我的页/onboarding 头像区 → toast「即将上线」 | 换肤功能未设计,`UserProfileEntity.avatarConfig` 字段结构待定 |
| invite(成员预览) | 邀请卡用静态剪影氛围区 | `RoomInfoEntity` 无 members 字段,真实成员头像/人数需扩 entity + rules(待决议) |
| room(成员数显示) | 我的房间页显示 presence 在线数 | 同上:设计要的是「N 名成员」,数据只有在线数 |
| room(踢人 / 房主移交) | 未实现 | 待产品决议(解散/改名/退出已完成) |
| 深链(Universal Links) | 仅 `cofit://` 自定义 scheme | 需域名 + AASA 托管 + Associated Domains entitlement |

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
| 2026-08-01 | dock 临时第 4 槽位 | ~~临时加「浏览房间」槽位~~ → **P4 已回收**:dock 恢复 房间/牌库/我的 三槽位,浏览房间从房间主界面右上「+」压栈(带返回 AppBar) |
| 2026-08-01 | 大位移 Transform 与命中测试 | Container/Transform 的 transform 只影响绘制不影响 hit-test 盒——扇形手牌几何改为真实坐标定位(sin/cos 弧线)+ 仅绕卡片自心的小角度旋转;后续做飞卡/爆发动画时同理 |
| 2026-08-01 | 旧页面弃用 | P5 已清理:删除 `auth_my_page.dart`、`room_main_page.dart`、`room_action_controls_card.dart`;**保留** `RoomCommunityPage`(仍是浏览页的「加入/创建房间」工具页入口)与 `room_browse_page` 相关旧组件——功能可用但视觉未重做,待房间浏览流程有定稿设计再翻新 |
| 2026-08-01 | 我的页取版 | 用户选定 10a(形象优先),且内容收敛到已实现功能;10a 其余项(累计时长/打卡/通知隐私)等对应功能落地时再补 |
| 2026-08-01 | 字体打包 | google_fonts 目前运行时拉取 Space Grotesk(有缓存);**上线前**把字体文件打进 assets 并关闭 runtime fetching |
| 2026-08-02 | 事件流 → 房间状态(实测问题 2) | 新增 domain 折叠:`ActionSession`(时间点建模:active 存 endsAt、paused 冻结剩余,剩余/过期是随 now 的派生规则)+ `RoomActivitySnapshot.apply/sweep`(乱序忽略、一人一会话、未知会话从 payload 自举、completed/过期会话保留 5s 后清扫)。接线:`roomBrowserProvider.activityByRoom` 折叠入库,`RoomMainView` 合并 presence+会话渲染,1s ticker 驱动倒计时/到点回待机。~~presence 写入侧(实测问题 1)仍未做~~ → **2026-08-10 阶段二已修**,见下行 |
| 2026-08-10 | 阶段二 M1:presence 写侧修复(实测问题 1 收尾) | ① `enterPresence` 支持携带 activity(运动中进新房间不再被抹成 idle);② `onAppResumed` 对所有已订阅房间重申 presence(重申必须刷新 `updatedAtEpochMs`,否则接收端 `applyPresenceStatus` 严格更新检查会静默丢弃;到点改发 idle);③ 自己 activity 的单一事实源 `room/provider/own_activity_status_provider.dart`(放 room 不放 action,避免 firestore↔action 循环依赖);④ 登出走 `AblyRuntimeNotifier.shutdown()`:逐房间 presence leave + 释放连接 |
| 2026-08-10 | 阶段二 M1:Auth 重构 + Google 登录 | `AuthRepository` 接口进 domain,全部 usecase/页面改 Riverpod 注入(AuthGate 不再手工 new);Google 登录用 google_sign_in **v7 API**(`GoogleSignIn.instance`+`authenticate()`,idToken-only);补密码重置;旧 `auth_login_page.dart` 删除,死目录 `features/authentication/` 删除。**Sign in with Apple 延后**:免费开发者账号无此 capability,等用户付费账号升级后走 E1-Apple 轨道(上架前必须完成,App Store 规则) |
| 2026-08-10 | 阶段二 M1:profile 特性 + onboarding 门控 | `users/{uid}` 文档 `{uid, nickname(≤20), avatarConfig, createdAt, updatedAt}`(rules:read 所有登录用户——昵称要被房间成员/邀请预览读;写仅本人;可选键 `activeDeckId` 为 A2 预留);AuthGate 三态门控:authState loading→splash / 无 user→登录页 / profile loading→splash(防闪) / 无 profile→onboarding / 有→AppShell;我的页昵称行(可编辑)接 profile |
| 2026-08-10 | 阶段二 M1:退出房间 | rules `rooms` update 加第三分支:仅允许成员精确移除自己的 `members[uid]`(其余字段逐字节不变,owner 禁退防失主);`FirebaseRoomRepository.leaveRoom` 事务:移除 members 条目 + 删 membership(房间已删除时仍清理残留 membership);旧 `leave_room_usecase`(Ably 语义)重命名为 `unsubscribe_room_realtime_usecase`,新 `leave_room_usecase` 为 Firestore 语义;入口=房间顶栏 ⋯ → RoomActionsSheet → 确认对话框 |
| 2026-08-10 | 新 token | `size.authFormMaxWidth = 360`(登录/onboarding 表单大屏最大宽度,seed v1) |
| 2026-09-16 | Apple 账号迁移 + E1-Apple 收官 | 付费账号为**新 Apple 账号** → bundle id 迁移 `com.passerbo.cofit → com.passerbo.cofitapp`(App ID 跨团队唯一);Firebase 项目内新增 iOS app(flutterfire configure 重生成 firebase_options/GoogleService-Info,Info.plist Google 回跳 scheme 换新 OAuth client)。**Sign in with Apple 实装**:entitlements + nonce 流(取消→AuthCancelledException 静默)+ 登录页 Apple 按钮转正(HIG 黑白款,`AuthProviderButton.apple` 变体);Google 按钮文案对齐 #19a「通过 Google 登录」。**边界(待产品决议)**:Apple 登录产生独立 Firebase uid,与既有 Google/邮箱账号不互通(linkWithCredential 未做);旧 Firebase iOS app 待真机验证后删除 |
| 2026-09-17 | 上架阻塞项清零 | ① **字体打包**:Space Grotesk 400/600/700 静态字重(官方变量字体切出,OFL)进 `assets/fonts/`,移除 `google_fonts` 依赖——离线首启不再掉字形。② **账号删除**(Apple 强制):我的页危险区入口 → 二次确认 → 重认证(Apple 顺带取授权码撤 token)→ 解散/退出全部房间 → 清空 `users/{uid}` 及 memberships/decks/cards/sessions → 注销 Auth 用户。rules 放开本人删除 profile 与 sessions(sessions 仍禁改)。**顺序由单测锁住**:清理必须先于注销,否则 uid 失效导致数据永久残留 |
| 2026-09-17 | E1-Apple 收官 + Apple 账号迁移 | 迁移到新付费 Apple 账号:bundle id `com.passerbo.cofit` → **`com.passerbo.cofitapp`**(旧 id 被旧免费账号占用,显式 App ID 跨团队唯一),团队 `J95TRWHWYM`,Firebase 内新建 iOS app 并换新 OAuth client(Info.plist 的 Google 回跳 scheme 同步替换)。**Sign in with Apple 实装并真机验证通过**——排查耗时的根因:`OAuthProvider('apple.com').credential()` **必须带 `accessToken: authorizationCode`**,漏传时 Firebase 报 `Invalid OAuth response from apple.com`,文案误导向 provider 配置(flutterfire#18289)。顺带:`main()` 增加启动错误边界(初始化失败不再白屏,直接摊出异常);`/keys/` 纳入 gitignore |
| 2026-08-12 | 阶段三:九屏 UI 全部落地(设计交接包 v3) | 交接包同步进 docs/(README + design_reference.html,新增定稿 #15–#20 与 #14a)。新 token:opacity 12 个(disabledFill/On、danger 系、toast、chart 系、silhouette 系、avatarInactive、backdropDim)+ size 12 个(cardPreview 系/typeBarHeight/historyChart 系/inviteBand/successBadge/brandStage/authGlow/loginFanCard 系)+ motion 3 个(burstRing/shimmer/createGlow)+ decor 2 个(loginFanTiltDeg/brandCompactScale)+ typography.letterSpacingWide。数据层补 `CustomCardRepository.updateCard`(#16b 编辑)。**与设计的已知偏差**:①房间行「N 名成员」改为 presence 在线数(RoomInfoEntity 无 members 字段,扩展需动 entity+rules,待决议);②创建卡成功后的滚动定位+外发光未做(toast 代替);③15a 行尾 popover 用 Material PopupMenu 映射(视觉近似);④拖动中样式用 ReorderableListView 默认提升效果(未做 lime 描边+虚线落点槽) |
| 2026-08-12 | 旧页面清理(阶段三) | 删除 `room_browse_page.dart`、`room_community_page.dart`、`action_template_launch_browser.dart`(开发期工具页,功能已被 #20c/#15/#16 正式页面覆盖);牌库页全部 SnackBar stub 接上真实交互,仅「分享给好友」「查看全部」仍为 stub(G4 social 未实现) |
| 2026-08-10 | 阶段二收尾批次:非 UI 数据/服务层 | ① **牌组 CRUD 补全**:`ActionDeckRepository` + updateDeck/deleteDeck,`setActiveDeckId` 可传 null 清除;create/update/delete 三个 usecase(名称 1..20 校验;删当前使用中的组时 active 顺移到剩余第一组);② **自建卡数据层(DRAFT)**:`users/{uid}/cards` + rules,`templateCardsProvider` 合并 官方+自建(自建读取失败不阻塞官方),删卡时自动从所有牌组摘除引用;③ **房间管理(无争议部分)**:owner 改名/描述/可见性(`updateRoomInfoUsecase`)+ 解散(`dissolveRoomUsecase`,删房+own membership,成员侧靠懒清理);**踢人/owner 移交仍待产品决议**;④ **G5 昵称接线**(见 G5 行)。全部无 UI,入口仍是 stub |
| 2026-08-10 | 阶段二 M3:会话历史持久化 | `users/{uid}/sessions/{sessionId}` 只追加打卡日志(rules:仅本人读写,update/delete 禁止,status 只收 'completed');挂钩点 `own_action_session_notifier.complete()` 发布 completed 事件后 fire-and-forget 落库(失败仅 debugPrint,不阻塞 UI/presence);我的页新增「运动」分组(累计时长/完成次数,客户端聚合最近 100 条)。**已知限制**:会话中 app 被杀 → 该次记录丢失(远端视图靠 endsAt sweep 兜底),STATUS 立此为据 |
| 2026-08-10 | 阶段二 A2:牌组云端化 | `users/{uid}/decks/{deckId}` `{deckId, name, cardTemplateIds, createdAt, updatedAt}`;activeDeckId 存 profile 文档可选键(跨设备同步,弃 shared_preferences);首启 `SeedDefaultDecksUsecase` 幂等播种(固定 id deck_1..3,与旧 stub 同款种子);repository provider 按登录态换绑(未登录 → 空 in-memory,widgetbook/测试不受影响) |
| 2026-08-10 | 阶段二 M2:邀请深链 | 链接格式 `cofit://room/<roomId>?h=<shareLinkHash>`(拼装/解析单一事实源 `invite/domain/invite_link_format.dart`;h 是社交礼仪门槛非安全边界)。pending-link 模式:`pendingInviteProvider` 启动即订阅 app_links(冷启动 getInitialLink + 热启动流),登录前到达的链接滞留,`InviteLinkGate`(包在 AppShell 外)消费并弹预览 sheet。导航接线:MaterialApp 挂全局 `appNavigatorKey`;`AppShell._index` 提升为 `appShellIndexProvider`(深链可驱动切 tab);RoomMainView `ref.listen` focusedRoomId 跟随跳房。建房改 sheet(`room_create_sheet_view.dart`),成功态主 CTA=分享邀请链接(share_plus),旧 `room_create_page.dart` 删除——创建和邀请是同一个动作。`shareLinkHash` 至此有了消费方 |

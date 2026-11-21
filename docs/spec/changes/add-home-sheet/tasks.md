# Tasks: add-home-sheet

## Now
2026-11-21:M1(T1–T6)、M2(T9–T11 除卡片飞行)、M3 的大部分(T12、T14、T15,T13 的一半)代码已写完;全量 `fvm flutter test` 321 个通过,`fvm flutter analyze` 无告警。
用户已在模拟器上试用过一轮(2026-11-21),反馈两条并已改:去掉今日推荐的飞行框;动画播完前不接受操作。agent 自己的 T7 逐项走查还没做。
没做完的:① T7 / T8 走查与手感;② 卡片飞行按用户决定去掉了(以后单独优化);③ T12 / T14 写在房间页里的那部分逻辑没有自动化测试(房间页没有测试夹具),只测了纯规则;④ T13 的「App 被系统结束后重开补播」;⑤ 好友第 8 个落点在台上有小人时的错位;⑥ T17 文档只更新了一部分。
下一步建议:用户在模拟器登录一次 → agent 做 T7 → 按看到的问题修;再补 ②③④。
实现任何界面任务前先走 `ui-implementation` skill,新数值先走 `design-tokens` skill。只有「今日推荐」一个模块时面板比较空,`add-daily-card-goal` 接在本 change 之后。

## M1 · 台子与小人(用占位模块即可验证)
- [x] T1 新增 design.md §8 的 token(先 `cofit.tokens.json`,再同步 Dart theme 文件)— owner: agent · verify: `fvm flutter analyze` 无新增告警;token 与 Dart 常量数值一致 · done 2026-11-21
  - evidence: `cofit.tokens.json` 新增 motion.stage* / sheetModule* / celebrateBeatStagger / avatarBoard / avatarLeave、decor.stage* / sheet* / fanSinkFadeBy、size.stageFootInset / sheetGrabberWidth / fanSink,已同步 `cofit_dimens.dart`;`fvm flutter analyze lib test/features` No issues
- [x] T2 小人动作:动画指令加「是否在台上」;新增 `idle_stand`、`board`、`leave` 三条 clip;编排器加两个只在待机生效的 ×1 反应;同步更新 `docs/avatar_bean_spec.md` — owner: agent · verify: 编排器单测(待机上台 / 下台、运动中上台不换 clip、反应播放中状态变化按最新续接);loop clip 首尾帧一致的单测 · done 2026-11-21
  - evidence: `avatar_motion_sequencer_test.dart` 新增「今日面板:上台 / 下台」7 个用例;`pose_sampler_test` 的 loop 首尾帧一致覆盖 `idle_stand`;新增 goldens `idle_stand.png` / `board.png` / `leave.png`(已人工看过 board 四帧);`docs/avatar_bean_spec.md` §5 增补三行
- [x] T3 位置层纯逻辑:拖动阈值与回差、松手判定(含快速甩动)、落点取实时台面、打断后的目标 — owner: agent · verify: 单测覆盖规格「拖动把手时小人跟随」「动画进行中可以继续操作」的全部场景 · done 2026-11-21
  - evidence: `lib/features/home_sheet/domain/stage_rules.dart` + `test/features/home_sheet/domain/stage_rules_test.dart`(17 个用例:回差阈值、松手与甩动判定、面板高度上限、好友区域下边距、起跳轨迹与实时落点、减弱动态效果)
- [x] T4 `RoomScene` 加「不画自己」选项;房间页把自己的小人放到独立一层,切换房间时固定不动,漂浮时外观与现在一致 — owner: agent · after: T2 · verify: widget test(切换房间自己的小人位置不变;演示房间仍画自己);现有 `test/features/room` 全过 · 与 T5、T6 改同一个文件 `room_main_view.dart`,不要并行 · done 2026-11-21
  - evidence: `RoomScene.showSelf`;房间页用 `StageAvatarLayer` 把自己的小人放在 PageView 之外的独立一层。`test/features/room`、`test/features/welcome_tour` 全过(演示房间仍画自己)。**缺**:房间页整页的 widget test(该页依赖大量 provider,目前没有测试夹具)——切换房间时小人不动这一条靠结构保证,待 T7 在模拟器上确认
- [x] T5 面板容器:进度值 `p` 驱动面板位移、手牌下沉、好友区域下边界;把手拖动;点小人 / 点空白 / 点把手;用一个仅 debug 的占位模块 — owner: agent · after: T1, T3, T4 · verify: widget test(冷启动默认展开且看不到手牌;点小人收起后手牌回来且出牌可用;好友都在面板上沿以上) · done 2026-11-21
  - evidence: `HomeStageController` + `HomeSheetPanel` + 房间页接线(手牌下沉淡出、好友区域下边距随展开程度变化、点空白收起、把手拖动);`test/features/home_sheet/presentation/home_stage_test.dart` 13 个用例。**缺**:同上,整页级的「冷启动默认展开且看不到手牌」待 T7 确认
- [x] T6 上台 / 下台编排:蓄力、弧线、缩放、落地扩散环与触感、名字行淡入淡出、台面下沉;可打断;读取系统「减弱动态效果」并走简化路径;debug 构建加全局慢放开关 — owner: agent · after: T2, T5 · verify: widget test(动画结束后的终态;中途再点立即掉头;减弱动态效果下无位移动画);模拟器录屏 · done 2026-11-21
  - evidence: 蓄力 / 弧线 / 缩放 / 落地扩散环(clip 内)/ 落地触感 / 名字行淡出 / 台面下沉 / 可打断 / 减弱动态效果,均在 `home_stage_test.dart` 有用例;debug 占位模块带全局慢放开关(5 倍)。测试中发现并修复:起跳中途掉头时面板会朝旧目标继续收起。**缺**:模拟器录屏(并入 T7)
- [ ] T7 模拟器走查:上台、下台、拖动、切换房间、运动中上台、小屏(iPhone SE)— owner: agent · after: T6 · verify: 各场景截图或录屏附在本任务下
  - 2026-11-21:未做。现有模拟器里都没有安装或登录过 App;需要用户在模拟器里登录一次(或同意用审核演示账号登录)后 agent 才能走查。
- [ ] T8 真机手感确认:拖动跟手、阈值、触感强度、动画快慢;把想调的数值告诉 agent — owner: me · after: T7 · verify: 用户说可以,或给出要改的 token

## M2 · 模块系统与今日推荐
- [x] T9 `home_sheet` feature:布局配置实体与内置默认值、模块接口与注册表、宿主动作、模块状态上报(加载中 / 有内容 / 无内容)— owner: agent · after: T5 · verify: 单测与 widget test(未知 id 被跳过;一个模块出错不影响其他;全部无内容时面板不出现且点小人无反应) · done 2026-11-21
  - evidence: `home_sheet/domain/entity/home_sheet_layout.dart`(内置默认值)、`presentation/module/home_sheet_module.dart`(模块规格、注册表、宿主接口、状态);房间页按布局取模块、全部无内容时 `setAvailable(false)`。测试:`home_sheet_module_test.dart`(顺序、未知与重复 id 被跳过、空清单、今日推荐三种状态)、`home_stage_test.dart`「面板不存在时」。**缺**:「一个模块出错不影响其他」目前靠各模块自己画空来保证,没有专门用例
- [x] T10 推荐策略接口 + 默认策略(手牌中最久没做过的一张)— owner: agent · verify: 单测(空手牌返回无;都没做过取第一张;按记录取最久没做的) · done 2026-11-21
  - evidence: `home_sheet/domain/recommend_card_strategy.dart` + `recommend_card_strategy_test.dart` 5 个用例;规则经 `recommendCardStrategyProvider` 注入,可整体替换
- [ ] T11 今日推荐模块 + 卡片飞到选卡正中 + 手牌「停在某张卡」动作 — owner: agent · after: T6, T9, T10 · verify: widget test(点推荐后手牌处于选卡状态且该卡在正中;卡不在手牌时进入普通选卡;手牌为空时模块不显示)
  - 2026-11-21 进度: 已做:`RecommendationModuleView` + 宿主 `focusFanOnCard`(手牌进选卡并停在该卡;不在手牌时进普通选卡)+ `activeHandProvider`;测试 `home_sheet_module_test.dart`「今日推荐模块」4 个用例。卡片飞行:模块把缩略卡位置交给宿主,房间页用 `playFly` 时长把一张类型色卡片飞到选卡正中(减弱动态效果时不飞)。**未做**:飞行卡用的是简化外观而不是真卡面、落定时没有与真卡无缝替换;房间页一侧「该卡在正中」的整页断言;实际效果未看过

## M3 · 完成庆祝、自动展开、远程布局
- [ ] T12 完成庆祝:完成事件先交给位置层,落到台上后再播完成动作;按模块顺序发节拍;面板已展开 / 正在选卡两种分支 — owner: agent · after: T6, T9 · verify: widget test(面板收起时完成 → 展开且小人在台上;节拍顺序;选卡中完成不打断)
  - 2026-11-21 进度: 已做:房间页监听自己的会话结束 → 升台途中小人保持运动状态(`_heldStatus`),落到台上才交给编排器播完成动作;节拍 `celebrations` 对齐完成动作第一次落地并带触感;已在台上 / 正在选卡两种分支。**未做**:自动化测试(房间页无夹具);目前没有消费节拍的模块(今日进度模块在 add-daily-card-goal)
- [ ] T13 欠的庆祝:本机记录、合并、有效期;接入冷启动恢复过期会话的路径 — owner: agent · after: T12 · verify: 单测(后台完成后回来播一次;两次合并;超期不播;恢复路径会记账)
  - 2026-11-21 进度: 已做:完成时正在选卡 / 牌组下拉打开 → 记下,退出后按有效期补播一次(`PendingCelebrationPolicy`,有单测);App 在后台时计时器在回到前台才触发,庆祝自然在回来时播放。**未做**:App 被系统结束后重开(冷启动恢复过期会话)时的补播与本机持久化
- [x] T14 自动展开规则(纯函数)+ 本机记录上次离开房间页的时间 — owner: agent · after: T5 · verify: 单测覆盖规格「面板自动展开」三个场景与冷启动 · done 2026-11-21
  - evidence: `home_sheet/usecase/auto_expand_policy.dart` + `auto_expand_policy_test.dart`(冷启动、完成、短暂离开、离开较久、关闭规则、面板关闭);房间页用 `AppLifecycleListener` 记离开时间(进程内即可,进程被结束即冷启动),回来后停顿 `stageAutoExpandDelay` 再展开。**缺**:房间页一侧的接线没有自动化测试
- [x] T15 远程布局:读取字符串参数 `home_sheet_layout`,解析与逐字段回退;`modules` 为空即关闭面板 — owner: agent · after: T9 · verify: 单测(非法 JSON、缺字段、类型不对、空数组、未知模块 id) · done 2026-11-21
  - evidence: `FeatureFlags.homeSheetLayout`(参数名 `home_sheet_layout`,默认空串)+ `HomeSheetLayout.parse`;`home_sheet_layout_test.dart` 8 个用例(非法 JSON、缺字段、类型不对、空数组、显式 null、未知 id 由注册表跳过);`feature_flags_test.dart` 新增 1 个
- [ ] T16 (想调整布局时才需要)在 Firebase console → Remote Config 新建字符串参数 `home_sheet_layout`,值为 design.md §12 形状的 JSON,发布 — owner: me · after: T15 · verify: 重启 App 后面板按新配置显示

## M4 · 收尾
- [ ] T17 文档:`docs/ui_overhaul/STATUS.md`(#6b 下半部分构成变化)、`docs/flows_status.md`、`docs/project_overview.md`、`CLAUDE.md` 的基建事实(新参数、新 feature)— owner: agent · after: T11, T15 · verify: 用户过目
- [ ] T18 `fvm flutter analyze` 零新增告警、全量 `fvm flutter test` 通过、iOS 模拟器构建通过 — owner: agent · after: T1–T15 · verify: 命令输出
- [ ] T19 打 TestFlight 包并在真机上完整走一遍(含锁屏完成后回来补播庆祝)— owner: me · after: T18 · verify: 用户确认;确认后归档本 change

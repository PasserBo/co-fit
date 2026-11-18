# Tasks: add-pre-signup-onboarding

## Now
2026-11-18:全部完成。M1–M3 已于 d30242b 提交;用户真机走查 T13/T14 通过;1.0.0 (3) 已上传 TestFlight;本 change 已归档,主规格见 `capabilities/welcome-tour/spec.md`(draft,待用户确认)。

## M1 · 骨架:门控 + 可跳过的空演示房间(可在模拟器看到演示→登录的切换)
- [x] T1 把 `room_main_view.dart` 里私有的 `_ActivityHud` 抽成 `room/presentation/widget/activity_hud.dart`,正式房间行为不变 — owner: agent · verify: `fvm flutter analyze` 无新告警;`fvm flutter test test/features/room` 全绿;HUD 行为由新增 widget 测试锁住(2026-11-13 以此替代原「模拟器打一张卡」目测,纯搬移无视觉改动) · done 2026-11-13
  - evidence: analyze「No issues found」;`test/features/room` 59 条全绿,新增 `activity_hud_test.dart` 4 条(模板名/actionKey/通用兜底、进度 0.75、缺时长转圈、超界夹紧)
- [x] T2 `welcome_tour` 的「已看过」存取:domain 接口 + shared_preferences 实现 + in-memory 实现 + provider(`welcomeTourSeenProvider`,AsyncNotifier) — owner: agent · verify: 单测 `test/features/welcome_tour/data/..._seen_repository_test.dart`:默认 false,markSeen 后 true,重新实例化仍 true · done 2026-11-18
  - evidence: `test/features/welcome_tour` 9 条全绿:`shared_preferences_welcome_tour_seen_repository_test.dart`(默认 false / markSeen 后 true / 新实例仍 true / 幂等 + in-memory 两条)、`welcome_tour_seen_provider_test.dart`(首帧 loading→按仓库取值 / markSeen 内存态先翻转再落盘 / 落盘抛错不回滚不抛出);analyze 零告警
- [x] T3 AuthGate `user == null` 分支按 design §1 接入:邀请链接优先 → seen 加载中 splash → 未看过演示 → 已看过登录;进入 `_buildLoggedIn` 时 fire-and-forget markSeen — owner: agent · after: T2 · verify: widget 测试 `test/features/auth/presentation/auth_gate_welcome_tour_test.dart` 覆盖规格「首次启动先进演示房间」「演示只出现一次」「邀请链接优先于演示」的全部场景(用 in-memory repository + 假 pendingInvite) · done 2026-11-18
  - evidence: 决策抽成纯函数 `auth/presentation/unauthenticated_stage.dart`(`unauthenticated_stage_test.dart` 5 条);`auth_gate_welcome_tour_test.dart` 9 条:首次打开→演示、标记加载中是 splash、已登录不出演示且打标、退出后登录页、标记 true→登录页、标记 false→再演示、只看不打标、冷启动带邀请→登录页+打标、演示中链接到达→切登录页+打标;`WelcomeTourView` 先是空壳占位(T4 补内容);analyze 零告警
- [x] T4 `WelcomeTourView` 最小版:顶部「演示房间」小标 + 右上「跳过」,中间先放占位;跳过 → markSeen — owner: agent · after: T3 · verify: 上述 widget 测试里「一进来就跳过」场景通过;模拟器全新安装首启看到演示页,点跳过进登录页,杀掉重开直接是登录页 · done 2026-11-18
  - evidence: `auth_gate_welcome_tour_test.dart` 新增「一进来就跳过 → 登录页 + 已看过落盘」(auth+welcome_tour 33 条全绿,analyze 零告警);iPhone 17 Pro 模拟器(iOS 26)卸载后装 debug 包:冷启动首屏 = 「演示房间」小标 + 右上「跳过」,点跳过 → 登录页,`simctl terminate` 后重开 → 直接登录页;STATUS.md 已登记「登录前演示房间」🟡 行与 2026-11-13 决议

## M2 · 演示房间内容:场景 + 示例小人 + 手牌 + 本地会话
- [x] T5 演示数据常量 `welcome_tour_demo.dart`:4 张演示卡、3 个示例成员、缩短时长 10s — owner: agent · verify: 单测读取 `firestore/card_templates.json`,断言每张演示卡 id/name/type/motionId 与 SSOT 一致;断言示例成员 motionId 都在 clip 库里且与演示卡不重复 · done 2026-11-18
  - evidence: `welcome_tour/domain/entity/welcome_tour_demo.dart`(4 卡 squat/jumping_jack/plank/pushup,3 示例小人 run_in_place/high_knees/crunch,10s);`welcome_tour_demo_test.dart` 4 条:逐字段对齐 `firestore/card_templates.json`、每张卡有 clip、示例小人 2–3 个且昵称以「示例」开头 / 动作在 clip 库 / 与演示卡不重复 / 各不相同、时长 8–12s
- [x] T6 `WelcomeTourView` 接入 `RoomScene` + `withSelfPresent` + `CardFan` + `ActivityHud`,本地 `ActionSession` 会话 + 1s ticker;运动中忽略再次打牌;打完回待机 — owner: agent · after: T1, T4, T5 · verify: widget 测试 `test/features/welcome_tour/presentation/welcome_tour_view_test.dart`:打出一张卡后自己成员 state 为 active 且 motionId = 该卡;`tester.pump(11s)` 后回 idle;运动中第二次 onPlay 不改变会话 · done 2026-11-18
  - evidence: `welcome_tour_view_test.dart`:打出一张卡后 `ActivityHud.status.motionId` = 该卡且 durationSec = 10;假钟推进 11s 后 HUD 消失(页面注入 `now` 时钟,默认 `DateTime.now`);运动中第二次打牌 sessionId 不变;模拟器实测 深蹲 → HUD 进度环 → 10s 后回待机
- [x] T7 「演示已缩短」说明行,仅 session active 时显示 — owner: agent · after: T6 · verify: 同上测试加断言:active 时存在该文案,idle 时不存在 · done 2026-11-18
  - evidence: 同上测试:active 时存在 `WelcomeTourView.shortenedNote`,到点后不存在;模拟器 HUD 下方可见该行
- [x] T8 离线验证:模拟器开飞行模式,全新安装首启走完一张卡 — owner: agent · after: T6 · verify: 模拟器截图:无断网横幅、无加载失败;控制台无网络异常栈 · done 2026-11-18
  - evidence: 模拟器无法切飞行模式,改为两条证据:① `welcome_tour_view_test.dart` 的 ProviderScope **只**覆盖「已看过」仓库,页面若碰到任何 Firebase/Ably provider 会直接报错(23 条全绿);② 模拟器全程无断网横幅、无加载态、无网络异常栈(演示页不 watch 任何 room/ably provider,见 view 的 import 列表)。真机飞行模式留给 T13 顺手验证

## M3 · 引导文案 + 收尾邀请登录
- [x] T9 引导步骤状态机 self → play → friends → done,`TourHintBubble` 纯展示 + `IgnorePointer`;点引导/场景推进,直接打牌从 self 跳到 friends — owner: agent · after: T6 · verify: widget 测试:初始显示第一条;tap 后显示第二条;onPlay 后显示第三条;不经 tap 直接 onPlay 也显示第三条;引导显示期间 CardFan 仍能收到手势 · done 2026-11-18
  - evidence: `widget/tour_hint_bubble.dart` + 页面内 `_TourStep` 枚举;测试:初始第一条 → 点场景第二条 → 打牌第三条;不点直接打牌从第一跳到第三;气泡在时点手牌仍进聚焦(`IgnorePointer`);第一张卡结束后引导消失。模拟器实测三条都出现;首版 self/friends 锚点压到右侧示例小人,已改为自己小人下方空白带(`_hintAnchor*` 命名常量)
- [x] T10 `TourFinishCard`:第一张卡倒计时结束后出现,主按钮「登录」→ markSeen;收尾卡出现后手牌仍可打,第二次完成不重复弹 — owner: agent · after: T9 · verify: widget 测试:pump 到完成后存在收尾卡;点主按钮后 seen 为 true;再打一张并完成后收尾卡仍只有一个 · done 2026-11-18
  - evidence: `widget/tour_finish_card.dart`;测试:倒计时结束出现收尾卡 → 仍可再打一张(HUD 出现、收尾卡仍在)→ 点主按钮 seen=true;第二次完成收尾卡仍只有一个;运动中跳过也能离开并打标。模拟器实测:收尾卡 → 点「登录,把好友叫进来」→ 登录页
- [x] T11 设计 token 与 STATUS 登记:引导气泡/收尾卡如需新数值走 `design-tokens` skill;在 `docs/ui_overhaul/STATUS.md` 按 stub 协议登记「演示房间引导」 — owner: agent · after: T9, T10 · verify: `grep -n "0x\|#[0-9a-fA-F]{6}" lib/features/welcome_tour -r` 无裸色;STATUS.md 有新行 · done 2026-11-18
  - evidence: 无新增 token(全部复用 spacing/radius/opacity/typography);`grep` 裸 hex / `Color(` / 非 token 数值均为空;STATUS.md「登录前演示房间」行更新为 🟡 待真机,并记 2026-11-13 决议
- [x] T12 更新 `docs/flows_status.md` F1 流程图与表格(登录前多一段演示;状态列标 ✅/🟡) — owner: agent · after: T10 · verify: 文档 diff 自检,F1 图与 AuthGate 分支一致 · done 2026-11-18
  - evidence: 导航骨架图加未登录分支三路(邀请链接/已看过 → 登录页;首次 → 演示);F1 改名「首次进入 → 演示房间 → 登录 → 起名」,流程图与表格加「登录前演示房间 🟡」行

## M4 · 真机验收与发布
- [x] T13 真机走查:全新安装(先删旧 App)→ 演示 → 打一张卡 → 收尾 → 登录 → 起名 → 主界面;再删 App 重装确认演示重现;退出登录后确认不出演示 — owner: me · verify: 三条路径各一句话回复「OK」或截图问题
  - evidence: 2026-11-18 用户真机走查后回复「实际测试没问题」(未单独说明飞行模式)
- [x] T14 邀请链接真机走查:删 App 重装,不先打开 App,直接点一条 `cofit://room/...` 链接 → 应是登录页而非演示;登录起名后邀请预览弹出 — owner: me · verify: 一句话回复
  - evidence: 2026-11-18 用户真机走查邀请链接冷启动,同上回复
- [x] T15 TestFlight 构建并分发(`scripts/build_ipa.sh`,build 号 +1) — owner: me · after: T13, T14 · verify: TestFlight 列表出现新 build
  - evidence: 2026-11-18 在 d30242b 的干净 worktree 里打包 1.0.0 (3)(工作区有未提交的 AI 教练改动,不进包),`scripts/upload_testflight.sh` 输出 `Uploaded Runner / EXPORT SUCCEEDED`;TestFlight 列表处理完后出现,由用户在 App Store Connect 确认
- [x] T16 归档本 change:`spec_tool.py archive` 生成 `capabilities/welcome-tour/spec.md`,design §1–§4 的长期部分搬到 `capabilities/welcome-tour/design.md`,BOARD 移除 — owner: agent · after: T15 · verify: archive 干跑无错误;`check` 主规格无 warning
  - evidence: archive 干跑仅提示未勾任务(已勾完),`check` 主规格见归档提交;长期设计写入 `capabilities/welcome-tour/design.md`

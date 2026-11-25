# Tasks: add-workout-memo

## Now
2026-11-25:T1–T3、T5 的代码与测试已完成;全量 `fvm flutter test` 393 个通过,`fvm flutter analyze` 无告警。未提交、未推送。
2026-11-25 用户决议后已**去掉次数**(编辑器、数据字段、配置、规则、测试),memo 只剩感受 + 一句话;下面各任务 evidence 里提到次数的部分已不存在。
**卡在 T4**:`firestore.rules` 新增的 `session_memos` 一段要用户确认 diff(次数去掉后 diff 变了,需要重新看);推送 main 之前,真实环境里写 memo 会被服务端拒绝(界面按保存失败处理)。
**没验证的**:模拟器上的演示账号没有任何运动记录,所以「刚才」模块、历史行的 memo、详情面板都**没有在实机上看过**,只有 widget test 覆盖。T6 的截图部分未完成。
下一步:用户确认规则 → 提交并推送 → 核对规则部署 → 真机做一张卡走一遍(T8)。

## M1 · 数据
- [x] T1 memo 实体、配置实体与解析(远程参数 `workout_memo_config`)、「刚才这张」与「是否问次数」的纯函数、保存用例(空则删)— owner: agent · verify: 单测(配置逐字段回退;时长内 / 外;最新一条;空 memo 走删除) · done 2026-11-25
  - evidence: `workout_memo/domain/`、`usecase/`;`workout_memo_domain_test.dart` 14 个用例(配置回退、目标时长、问次数、空 memo、摘要、次数加减、空则删)
- [x] T2 云端与内存保存实现、provider(乐观更新 + 失败回滚、到期重算)— owner: agent · after: T1 · verify: 单测(保存后立即可见;失败回滚;到期后目标消失) · done 2026-11-25
  - evidence: `data/`、`provider/workout_memo_providers.dart`;乐观更新 + 只回滚出错那一条;到期由定时器重算。覆盖在 `workout_memo_view_test.dart`(保存失败回滚、App 开着超过时长模块消失)
- [x] T3 `firestore.rules` 新增 `session_memos` 一段;账号删除清理列表加上它 — owner: agent · verify: 把 diff 贴给用户;账号删除单测仍通过 · done 2026-11-25
  - evidence: `firestore.rules` 新增 `hasValidMemoShape` / `hasValidMemoValues` 与 `session_memos` 匹配段;`FirebaseUserDataEraser` 清理列表加 `session_memos`;`test/features/profile` 通过。diff 已贴给用户,**待确认**
- [ ] T4 确认规则 diff;推送 main 后 `gh run list --workflow=deploy-rules.yml` 为 success — owner: me(确认)→ agent(推送后核对)· after: T3 · verify: CI 输出

## M2 · 界面
- [x] T5 编辑器、今日面板「刚才」模块(登记 + 默认布局)、运动历史行露出与可点、详情面板、今日进度点开历史 — owner: agent · after: T2 · verify: widget test 覆盖规格各场景 · done 2026-11-25
  - evidence: `MemoEditor`、`MemoEditorView`、`LastSessionMemoModuleView`、`WorkoutMemoSheetView`;历史行 `memoSummaries` / `onRecordTap`;今日进度 > 0 时点正文打开运动历史;默认布局 = 刚才这张 → 今日进度 → 今日推荐。`workout_memo_view_test.dart` 18 个用例覆盖规格各场景(账号删除一条由清理列表保证,无单独用例)。测试中发现并修复:连点加减时按旧值计算会丢步
- [ ] T6 analyze 零告警、全量测试通过、模拟器看一眼外观 — owner: agent · after: T5 · verify: 命令输出 + 截图
  - 2026-11-25 进度: analyze No issues;全量测试 397 通过;模拟器构建通过。**未做**:截图——演示账号 0 条记录,没有可看的内容

## M3 · 收尾
- [ ] T7 文档:`CLAUDE.md`(新集合、新参数、新 feature)、`docs/ui_overhaul/STATUS.md`、看板 — owner: agent · after: T6 · verify: 用户过目
- [ ] T8 真机确认:做完一张卡后模块出现的时机是否和庆祝抢注意力;面板变高后是否需要滚动;三档感受的文案 — owner: me · after: T4, T6 · verify: 用户说可以,或给出要改的地方

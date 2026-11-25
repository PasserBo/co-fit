# Tasks: add-daily-card-goal

## Now
2026-11-25:T1–T6 的代码与测试已完成:全量 `fvm flutter test` 365 个通过,`fvm flutter analyze` 无告警,模拟器(iPhone 17 Pro,演示账号 Review Room)上看过模块外观与目标选择。
**没验证的**:在模拟器 / 真机上真正完成一张卡,看数字是否在小人落地那一下变化、达成反馈的强度(会给演示账号写一条真实运动记录,等用户同意或由用户自己试)—— T8。
下一步:用户试用 → 按反馈调数值;T7 文档已更新 `CLAUDE.md`、`STATUS.md`、看板。未提交。

## M1 · 规则与数据
- [x] T1 新增 design.md §8 的 token(先 `cofit.tokens.json`,再同步 Dart)— owner: agent · verify: analyze 无告警;JSON 与 Dart 数值一致 · done 2026-11-25
  - evidence: `cofit.tokens.json` 新增 size.progressRing / borderWidth.progressRing / motion.progressRoll / goalReachedPulse / dailyProgressBeatTimeout / decor.goalReachedPulseScale,已同步 `cofit_dimens.dart`
- [x] T2 计量方式接口 + `cards` / `minutes`、配置实体与解析(远程参数 `daily_goal_config`)、今日进度纯函数 — owner: agent · verify: 单测(只算当天完成的;跨零点归完成日;换计量方式;配置逐字段回退) · done 2026-11-25
  - evidence: `daily_goal/domain/`、`usecase/compute_daily_progress.dart`;`daily_goal_config_test.dart` 4 个、`compute_daily_progress_test.dart` 5 个用例;远程参数 `daily_goal_config`(`FeatureFlags.dailyGoalConfig`)
- [x] T3 本机目标保存 + 「今天」的更新(零点、回到前台)+ provider 接线 — owner: agent · after: T2 · verify: 单测(没存过用默认值;按用户与计量方式分开;过零点后进度归零) · done 2026-11-25
  - evidence: `daily_goal/data/`、`provider/daily_goal_providers.dart`;`daily_goal_providers_test.dart` 6 个用例(默认值、保存、按用户 / 计量方式分开、可选值、过零点)

## M2 · 界面
- [x] T4 进度环、今日进度模块(三种状态、引导到今日推荐、跟随庆祝节拍、达成反馈、减弱动态效果)、目标选择面板;登记到模块表并改默认布局 — owner: agent · after: T1, T3 · verify: widget test 覆盖规格各场景 · done 2026-11-25
  - evidence: `DailyProgressModuleView`、`ProgressRing`、`DailyProgressSummary`、`DailyTargetSheet`;已登记到模块表,内置默认布局改为今日进度 + 今日推荐;`daily_progress_module_test.dart` 16 个用例覆盖规格各场景。测试中发现并修复:节拍监听没有注册(写成了惰性初始化)、目标选项被撑满整行
- [x] T5 运动历史页顶部的今日进度 — owner: agent · after: T4 · verify: widget test(有记录时显示;空状态不显示) · done 2026-11-25
  - evidence: `DailyProgressHistoryHeaderView` + `WorkoutHistoryBody.header`;widget test「运动历史页顶部显示同样的今日进度」。空状态走原有分支,不经过这段代码,没有单独用例

## M3 · 收尾
- [x] T6 analyze 零告警、全量测试通过、模拟器构建并看一眼模块外观 — owner: agent · after: T4, T5 · verify: 命令输出 + 截图 · done 2026-11-25
  - evidence: analyze No issues;全量测试 365 通过;模拟器截图确认:0 / 2 张 +「从今日推荐开始」、目标面板 5 个选项、选 3 后变 0 / 3 张。**没做**:完成一张卡的实际动画
- [x] T7 文档:`CLAUDE.md`(新参数、新 feature)、`docs/ui_overhaul/STATUS.md`、看板 — owner: agent · after: T6 · verify: 用户过目 · done 2026-11-25(待用户过目)
- [ ] T8 真机确认:完成一张卡时数字在小人落地那一下变化、达成反馈的强度 — owner: me · after: T6 · verify: 用户说可以,或给出要改的数值
- [ ] T9 (想调整时才需要)Firebase console → Remote Config 新建字符串参数 `daily_goal_config`(形状见 design.md §2)并发布 — owner: me · verify: 重启 App 后目标默认值 / 可选值变化

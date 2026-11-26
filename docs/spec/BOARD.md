# Board

| Change | State | Next step | Owner |
|---|---|---|---|
| [add-room-create-and-discovery](changes/add-room-create-and-discovery/proposal.md) | in-progress | 2026-11-21 已合进 main(分支 `claude/community-basics-ab39ed`,未推远端);待真机走查(T11)后归档 | me |
| [add-ai-coach-beta](changes/add-ai-coach-beta/proposal.md) | in-progress | M1 实现(tasks.md);M2 需先启用 Firebase AI Logic | agent |
| [add-home-sheet](changes/add-home-sheet/proposal.md) | in-progress | M1–M3 大部分代码完成(测试 321 过),**未在模拟器 / 真机上看过**;下一步:用户在模拟器登录 → T7 走查;再补卡片飞行、房间页测试、被结束后补播,见 [tasks.md](changes/add-home-sheet/tasks.md) | me(登录)→ agent |
| [add-usage-analytics](changes/add-usage-analytics/proposal.md) | idea | 比较今日面板不同布局所需的使用数据;不阻塞 add-home-sheet;用户定统计方式 | me |
| [add-daily-card-goal](changes/add-daily-card-goal/proposal.md) | in-progress | 代码与测试完成(未提交);待用户试用:完成一张卡时数字随小人落地变化、达成反馈(T8),见 [tasks.md](changes/add-daily-card-goal/tasks.md) | me |
| [add-workout-streak](changes/add-workout-streak/proposal.md) | idea | 今日面板的连胜模块 + 历史页日历;design 需规划个人运动汇总与可替换的连胜规则 | agent |
| [add-workout-reminder](changes/add-workout-reminder/proposal.md) | idea | 依赖 add-daily-card-goal;落地体验待首屏方案 | agent |
| [add-avatar-unlocks](changes/add-avatar-unlocks/proposal.md) | idea | 依赖 add-workout-streak;里程碑与奖励做成独立清单 | agent |
| [add-workout-memo](changes/add-workout-memo/proposal.md) | in-progress | 代码与测试完成(未提交,已按用户决议去掉次数);**等用户确认 `firestore.rules` 的 diff**,之后提交推送、核对规则部署、真机走一遍,见 [tasks.md](changes/add-workout-memo/tasks.md) | me |
| [add-character-page](changes/add-character-page/proposal.md) | idea | 把「我的」拆成小人页 + 设置,运动记录归小人;排在 add-workout-memo 之后;有 5 个待定问题 | me |
| [add-card-prescription](changes/add-card-prescription/proposal.md) | in-progress | 代码与测试完成(未提交);**等用户确认 `firestore.rules` 的 diff**(运动记录新增两个可选字段),见 [tasks.md](changes/add-card-prescription/tasks.md) | me |
| [add-partner-start-push](changes/add-partner-start-push/proposal.md) | in-progress | 已提交推送 main,Function 已上线,rules 由 CI 部署;下一步真机双账号走查(T21);CI 的 Functions 部署权限待补(T19 B),见 [tasks.md](changes/add-partner-start-push/tasks.md) | me |

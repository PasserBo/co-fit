# Design: add-workout-memo

> 行为见 [specs/workout-memo/spec.md](specs/workout-memo/spec.md)。

## 1. 数据

memo 与运动记录分开:`users/{uid}/session_memos/{sessionId}`,文档 id = 运动记录的 id。

| 字段 | 类型 | 说明 |
|---|---|---|
| `sessionId` | string | 必填,等于文档 id |
| `templateId` | string | 必填;以后「按卡看上次」用 |
| `completedAt` | timestamp | 必填,抄自运动记录;用来按时间取最近的 memo |
| `updatedAt` | timestamp | 必填 |
| `feel` | string | 可选,感受档位的 key(不是文案) |
| `note` | string | 可选,1–500 字(界面上限更小,见 §3) |

- 两个可选字段都没有时不保存空文档:保存时发现 memo 为空 → 删除文档。
- 读取:按 `completedAt` 倒序取最近 100 条,与运动历史的 100 条对应;用 `sessionId` 对上。
- 存的是档位 key,文案和表情在配置里——改文案不影响已有数据;配置里已经没有的 key 显示为 key 本身。

## 2. 权限规则(需用户确认 diff 后随 main 推送由 CI 部署)

新增一段,仅本人可读、建、改、删;字段用 `hasOnly` 锁住;改的时候 `sessionId` / `templateId` / `completedAt` 不能变。运动记录本身的规则不动(仍然只能新建)。
账号删除:清理列表加上 `session_memos`(顺序约束不变:先清数据再注销账号)。

⚠️ 规则部署之前,新版 App 写 memo 会被拒绝(界面按「保存失败」处理)。所以这个 change 的代码和规则要一起推送。

## 3. 配置

沿用远程开关机制,新增字符串参数 `workout_memo_config`;空串 = 内置默认值:

```json
{
  "feels": [
    {"key": "easy", "label": "轻松", "emoji": "😌"},
    {"key": "ok", "label": "刚好", "emoji": "🙂"},
    {"key": "hard", "label": "吃力", "emoji": "😮‍💨"}
  ],
  "promptWindowMinutes": 30,
  "noteMaxLength": 100
}
```

- 逐字段回退,永不抛出(与 `home_sheet_layout`、`daily_goal_config` 相同)。
- `feels` 为空数组 = 不问感受(模块只剩文字)。
- **不问次数 / 距离 / 重量**(2026-11-25 用户决议):「量」是卡片自带的信息,不是做完才填的;见提案 `add-card-prescription`。

## 4. 「刚才这张」是谁

纯函数:(最近的运动记录、现在、可补记时长)→ 最新的一条记录,前提是它的完成时间在时长之内;否则没有。
到期时间由定时器驱动重新计算(App 开着也会消失);回到前台时同样重算。

## 5. 保存

- 界面改动先落在本地状态(立即显示),再写云端;写失败 → 回滚到之前的值并提示。
- 同一条 memo 的连续操作按顺序各写一次整份文档(文档很小),不做合并。

## 6. 界面

- **编辑器**(纯展示,模块与详情面板共用):感受档位一排(每个是「表情 + 文案」,等宽)、「写一句」一行(有文字时显示开头)。
- **今日面板模块** `last_session_memo`:标题「刚才 · 卡名」+ 编辑器。没有目标时状态为「无内容」,面板里不出现。内置默认布局变为 `["last_session_memo", "daily_progress", "recommendation"]`。
- **运动历史行**:第二行在「类型 · 时长」后面接 memo 摘要(表情 + 文案 · 文字开头);整行可点。
- **详情面板**(底部弹层):卡名、时间、编辑器、「删除 memo」(有 memo 时才出现,用统一的确认弹层)。
- **今日进度**:进度 > 0 时点模块正文打开运动历史页;= 0 时维持「引导到今日推荐」。

模块出现的时机:运动记录一到就出现(随面板升起时的模块依次出现动画),没有专门等庆祝节拍。是否会和今日进度的庆祝抢注意力,要在实机上看(调研标出的不确定项)。

## 7. token

不新增。感受档位的高度用现有的最小点击高度;选中态用 primary 的淡底 + 描边(与目标选择面板一致);其余复用现有间距、圆角与颜色。

## 8. 代码落点

| 内容 | 位置 |
|---|---|
| memo 实体、配置实体、保存接口 | `lib/features/workout_memo/domain/` |
| 「刚才这张」、保存(空则删) | `lib/features/workout_memo/usecase/` |
| 云端与内存实现 | `lib/features/workout_memo/data/` |
| 接线(memo 列表与乐观更新、配置、当前目标) | `lib/features/workout_memo/provider/` |
| 编辑器、摘要文字(纯展示) | `lib/features/workout_memo/presentation/widget/` |
| 今日面板模块、详情面板 | `lib/features/workout_memo/presentation/view/` |
| 历史行露出与可点 | `lib/features/action/presentation/` |
| 模块登记、默认布局 | `lib/features/home_sheet/` |
| 规则 | `firestore.rules` |

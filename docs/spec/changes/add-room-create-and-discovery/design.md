# Design: add-room-create-and-discovery

## 调研:同类社区型 App 的「建房 + 发现」

| 产品 | 建群/建房 | 发现 | 加入 |
|---|---|---|---|
| Discord | 名称 + 图标(+ 模板);默认私有,只有满足条件的社区服务器才能开「服务器发现」 | 发现页:分类、关键词搜索、在线人数/成员数 | 公开服务器一键加入;可选「成员筛选」规则确认 |
| Strava 俱乐部 | 名称、运动类型、地点、简介、公开/私密 | 按名称、地点、运动类型搜索;成员数是主要信号 | 公开直接加入,私密需管理员批准 |
| Zwift | 官方活动日历 + 私人 Meetup | 按时间排序的活动列表 | 报名 / 邀请 |
| Clubhouse | 开放 / 社交 / 私密三档房间 | 走廊列表:按社交关系与实时人数排序 | 开放房间直接进入 |
| Forest / Focusmate | 房间码 / 时段匹配 | 基本没有房间发现;靠邀请码或系统匹配 | 输入码 / 预约 |

归纳的最小集合:**建房表单(名称 + 简介 + 公开/私密)→ 公开列表(人数信号)→ 名称搜索 → 预览 → 一键加入**。分类/标签、地点、审核、人数上限、按社交关系推荐都建立在「房间已经很多」之上;Forest/Focusmate 这类小体量产品干脆不做发现。冷启动期 CoFit 只需要最小集合,而且「公开」应当是默认值,否则列表永远是空的。

## 本期取舍

- 做:建房整页、公开列表(成员数排序)、名称/简介搜索、预览加入、空态/失败/下拉刷新、三个入口。
- 不做:分类标签、地点、按「正在运动人数」排序(要对每个公开房间做实时在线查询)、加入审核、人数上限、服务端分页与全文搜索、举报入口前置到列表(进房后已有举报)。

## 数据与服务端

- **不改 `firestore.rules`**:`rooms` 读取对所有登录用户开放;成员自助加入那一支只校验「只改自己的 members 条目、角色是 member」,不校验 shareLinkHash(hash 一直只在客户端校验)。因此公开房间的「直接加入」走现有 `joinRoom` 事务即可。
  - 已知含义(不是本 change 引入的):知道房间 ID 的人本来就能加入任何房间,「仅邀请」只是不出现在列表里,不是访问控制。若要真正的私密房间,需要另立 change 在 rules 里校验 hash 或改为审批。
- **不建复合索引**:查询只用 `where('visibility', '==', 'public').limit(100)`,走自动单字段索引。排序(成员数 → 创建时间)和搜索在客户端做。`firestore.indexes.json` 不随 CI 部署,能不用就不用。
  - 超过 100 个公开房间后,列表只会是其中任意 100 个(按文档 ID),届时需要:给房间加 `memberCount` 冗余字段 + 复合索引 + 服务端分页,搜索另找方案(proposal › Open questions)。
- 成员数 = `members` map 的键数(含房主),即 `RoomInfoEntity.memberIds.length`,已有字段,无新增。
- 离线:先 `Source.server`,失败退回 `Source.cache`;缓存为空才抛错 → 页面显示「加载失败 + 重试」。`publicRoomsProvider` 关闭 Riverpod 3 自动重试,避免失败时一直转圈。
- 新建房间默认可见性改为 `public`;房名 ≤ 30、简介 ≤ 120(`RoomInfoLimits`,表单 `maxLength` + usecase 校验;rules 不限长,旧房间不受影响)。

## 客户端结构

| 位置 | 内容 |
|---|---|
| `room/data/firebase_room_repository.dart` | `fetchPublicRooms(limit)` |
| `room/usecase/fetch_public_rooms_usecase.dart` | 取数 + 纯函数 `sortPublicRooms` / `filterRoomsByQuery`(单测) |
| `room/provider/public_rooms_provider.dart` | `publicRoomsProvider`(autoDispose,无自动重试) |
| `room/presentation/room_navigation.dart` | `enterJoinedRoom`:刷新已加入列表 → 聚焦 → 切房间 tab → `popUntil(isFirst)`,建房/加入/我的房间「进入」共用 |
| `room/presentation/view/room_create_page_view.dart` | 建房整页(替代旧建房 sheet 的表单部分) |
| `room/presentation/widget/room_created_sheet.dart` | #20b「已就绪」分享卡,建房成功后弹在房间页上 |
| `room/presentation/view/room_discover_page_view.dart` | 发现页(搜索 + 列表 + 空态/失败) |
| `room/presentation/view/public_room_preview_sheet_view.dart` | 预览 + 加入 |
| `room/presentation/widget/public_room_tile.dart`、`room_visibility_option.dart` | 纯展示组件 |
| `core/widget/app_bar_filled_action.dart` | AppBar 里的主按钮(见下) |

## Bug:「我的房间」返回键无反应

根因:全局 `filledButtonTheme.minimumSize = Size.fromHeight(44)`,宽度是无穷。「我的房间」有房间时 AppBar `actions` 里放了 `FilledButton.icon(新建)`,actions 给的是无界宽度 → `BoxConstraints forces an infinite width` 布局断言;release 下整条工具栏布局失败,左上返回键拿不到点击。边缘右滑是路由自身的手势,不经过 AppBar,所以还能关闭。空列表时不显示「新建」,所以空态下返回键正常——这也是为什么它看起来时好时坏。

修法:新增 `AppBarFilledAction`(覆盖 `minimumSize` 为 44×44),AppBar 里的主按钮一律用它;回归测试 `test/features/room/presentation/view/my_rooms_page_back_test.dart` 用「已加入两间房」的状态锁住。

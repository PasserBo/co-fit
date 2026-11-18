# Tasks: add-room-create-and-discovery

## Now
M1–M4 agent 任务全部完成(模拟器走查 + analyze/test 绿)。剩 T11 真机双账号走查、T12 Review Room 可见性决定,均为 me。分支 `claude/community-basics-ab39ed` 未推送、未合并,等用户决定。无 rules / 索引改动,不涉及 CI 部署。

## M1 · Bug:「我的房间」返回键
- [x] T1 定位返回键无反应的根因 — owner: agent · verify: 复现测试先红后绿 · done 2026-11-19
  - evidence: 根因见 design.md「Bug」;修前测试报 `BoxConstraints forces an infinite width`
- [x] T2 AppBar 主按钮改用 `AppBarFilledAction`,补 widget 测试 — owner: agent · after: T1 · verify: `my_rooms_page_back_test.dart` 绿 + 模拟器点返回能关 · done 2026-11-19
  - evidence: `tapping back closes MyRoomsPageView when rooms are listed`;模拟器截图见下方 M4

## M2 · 新建房间页
- [x] T3 `RoomInfoLimits` + usecase 长度校验,默认可见性改为公开 — owner: agent · verify: analyze + 单测 · done 2026-11-19
- [x] T4 建房整页 + 可见性单选卡 + 「已就绪」分享卡改为进房后弹出 — owner: agent · after: T3 · verify: widget 测试 `RoomCreatePageView defaults to public…` / `name field caps…` · done 2026-11-19
- [x] T5 入口:房间空态、我的房间、我的页房间分组、发现页 — owner: agent · after: T4 · verify: 模拟器走查 · done 2026-11-19

## M3 · 发现公开房间
- [x] T6 仓库 `fetchPublicRooms` + 排序/搜索纯函数 + provider — owner: agent · verify: `fetch_public_rooms_usecase_test.dart` · done 2026-11-19
- [x] T7 发现页(搜索、列表、空态、失败重试、下拉刷新)+ 预览加入 — owner: agent · after: T6 · verify: widget 测试 `RoomDiscoverPageView …` 三条 · done 2026-11-19
- [x] T8 入口:房间空态、我的房间 AppBar 与空态、我的页房间分组 — owner: agent · after: T7 · verify: 模拟器走查 · done 2026-11-19

## M4 · 验收
- [x] T9 模拟器走通三项并截图 — owner: agent · after: T2, T5, T8 · verify: 截图 · done 2026-11-19
  - evidence: iPhone 17 Pro 模拟器(审核演示账号)截图 12 张,存于会话笔记目录 `community-basics-evidence/`(不入库:含线上真实房间名):01–02 我的房间 AppBar 正常 + 点返回关闭;03–06 发现列表按人数排序 / 搜索「gym」/ 预览 / 加入并进入;07–09 建房默认公开 / 填写 / 进房后弹「已就绪」;10–12 我的页房间分组 / 从我的页进房切回房间 tab。走查后已退出加入的房间、解散测试房间
- [x] T10 `fvm flutter analyze` 零告警、`fvm flutter test` 全绿 — owner: agent · verify: 命令输出 · done 2026-11-19
  - evidence: `No issues found!`;`+250: All tests passed!`
- [ ] T11 真机走查:建一间公开房间,另一个账号在「发现房间」搜到并加入 — owner: me · after: 合并到 main · verify: 两台设备上都看到对方小人
- [ ] T12 决定审核演示账号的 Review Room 是否改为公开(现为仅邀请;改公开后所有用户都能在发现页看到它)— owner: me · verify: 若改,同步 `scripts/seed_review_account.py`

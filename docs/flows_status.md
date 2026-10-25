# CoFit 用户流程与页面完成度(2026-10-22 盘点)

> 盘点基准:`main` @ 034a161 之后的工作树。设计进度明细仍以 [ui_overhaul/STATUS.md](ui_overhaul/STATUS.md) 为准,本文只回答两个问题:**用户能走通哪些路径**、**每个页面离上架差什么**。
>
> 状态图例:✅ 可上架 / 🟡 可用但有占位或已知边界 / ⛔ 阻塞上架 / ⬜ 未做(v2)

## 1. 导航骨架

```
main() ──► AuthGatePage(三态门控)
            ├─ authState loading ──────────────► Splash
            ├─ user == null ──────────────────► LoginPageView
            ├─ profile loading ───────────────► Splash(防闪)
            ├─ profile == null ───────────────► OnboardingPageView
            └─ profile != null ───────────────► InviteLinkGate ▸ AppShell
                                                   ├─ [房间] RoomMainView
                                                   ├─ [牌库] CardLibraryPage
                                                   └─ [我的] MyPageView
```

- AppShell = `IndexedStack` + 左上悬浮 dock(房间/牌库/我的 三槽位),无底部导航。
- 工具页一律 `Navigator.push` 压栈,带返回 AppBar;表单与确认类一律 bottom sheet / dialog。
- 深链(`cofit://room/<id>?h=<hash>`)在登录前到达会滞留,登录后由 `InviteLinkGate` 弹邀请预览。

## 2. 用户流程

### F1 首次进入 → 登录 → 起名

```
LoginPageView ─(Apple / Google / 邮箱)─► OnboardingPageView(昵称必填)─► AppShell[房间]
     └─ 邮箱:注册 / 登录 / 忘记密码(重置邮件)
```

| 步骤 | 状态 | 备注 |
|---|---|---|
| 三种登录 | ✅ | Apple 2026-09-17 真机验证;Apple uid 与 Google/邮箱 uid 不互通(待产品决议) |
| 取消登录 | ✅ | `AuthCancelledException` 静默 |
| Onboarding 起名 | ✅ | 空名禁用 CTA |
| Onboarding 形象区 | 🟡→✅ | 原「形象定制 即将上线」角标 + toast,本次盘点已移除(审核指南 2.1 不接受占位) |

### F2 房间:进入 → 看小人 → 打牌运动

```
AppShell[房间]
  ├─ 无房间:空态 ──► 「新建房间」/「手动输入 ID」(本次改为直接建房,不再只给「浏览」)
  └─ 有房间:RoomMainView(PageView 左右滑切房)
       ├─ 顶栏 ⋯ ──► RoomActionsSheet
       │     房主:编辑信息 / 邀请好友 / 成员管理(新) / 举报(新) / 解散
       │     成员:举报(新) / 退出房间
       ├─ 顶栏 + ──► MyRoomsPageView(我的房间列表 / 新建 / 手输 ID)
       ├─ 扇形手牌 tap ──► 聚焦模式 ──► 上滑打出 ──► HUD 倒计时
       └─ 牌组 chip ──► DeckPopover ──► 查看全部(_DeckSheet)
```

| 步骤 | 状态 | 备注 |
|---|---|---|
| 房间场景(presence 气泡 + 昵称) | ✅ | 头像为占位几何小人,Rive 范围外 |
| 打牌 → 事件流 → 倒计时 → 回待机 | ✅ | 会话中 app 被杀:下次启动补记打卡 / 恢复倒计时(2026-10-26) |
| 切房 / 切牌组 | ✅ | |
| 建房 → 成功态 → 分享链接 | ✅ | 分享文案含 `cofit://`,iMessage 中不可点(无 Universal Links) |
| 房主改名/描述/可见性 | ✅ | |
| 房主解散 | ✅ | 成员侧懒清理 |
| 成员退出 | ✅ | rules 禁止房主退出 |
| 房主移出成员(踢人) | ⛔→✅ | UGC 合规(指南 1.2)必需。本次新增 `RemoveRoomMemberUsecase` + 成员管理 sheet;被移出者靠懒清理感知 |
| 举报房间/成员 | ⛔→✅ | 本次新增 `reports` 集合 + 举报 sheet(房主与成员都可用) |
| 房间页连接状态(断网/未配置/重连) | ⛔→✅ | 2026-10-26 新增提示条,live 时不显示 |
| 房主移交 | ⬜ | v2,首版靠解散 |
| 能量爆发粒子 / 飞卡动画 | ⬜ | 润色项 |

### F3 邀请:链接 → 预览 → 加入

```
分享文本 ──► 对方点 cofit:// ──► app_links ──► pendingInviteProvider
   ├─ 未登录:滞留 → 登录/起名后弹出
   └─ 已登录:InvitePreviewSheetView ──► 加入 ──► 跳到该房间
                                        └─ 失效态「知道了」
```

| 步骤 | 状态 | 备注 |
|---|---|---|
| 冷/热启动解析 | ✅ | |
| 预览 → 加入 → 聚焦跳房 | ✅ | |
| 预览的成员剪影 | 🟡 | 静态装饰,`RoomInfoEntity` 本次补了 `memberIds`,预览可改为真实人数(未改,留待设计) |
| 没装 app 的人点链接 | ⛔(体验) | 需要 Universal Links:域名 + AASA。和隐私政策共用一个域名即可 |

### F4 牌库:浏览 → 自建卡 → 牌组

```
AppShell[牌库]
  ├─ 牌库 tab:按类型分组 ──► 卡片 tap ──► CardDetailSheetView(加入牌组 / 编辑 / 删除)
  │                       └─ ＋ 新建自建卡 ──► CustomCardFormSheetView
  └─ 我的卡组 tab:DeckListBody ──► DeckDetailPageView(改名 / 排序 / 移除)
                                └─ 加卡 ──► DeckAddCardsSheetView
```

| 步骤 | 状态 | 备注 |
|---|---|---|
| 官方卡 + 自建卡合并展示 | ✅ | 自建卡读取失败不阻塞官方 |
| 自建卡增删改 | ✅ | 删卡自动从牌组摘除 |
| 牌组增删改、排序、设为使用中 | ✅ | 首启幂等播种 3 组 |
| 卡片「分享给好友」↗ | 🟡→✅ | 原 SnackBar「开发中」,本次隐藏入口(social v2) |
| 类型行「查看全部」 | 🟡→✅ | 原 SnackBar「开发中」,本次隐藏入口 |
| 创建后滚动定位 + 外发光 | ⬜ | 润色项 |

### F5 我的:资料 → 历史 → 账号

```
AppShell[我的]
  ├─ hero(小人 + 昵称 + @handle)
  ├─ 统计(房间 / 牌组 / 卡牌)
  ├─ 运动(累计时长 / 完成次数)──► WorkoutHistoryPageView
  ├─ 账号(昵称可编辑 / 邮箱)
  ├─ 退出登录
  └─ 删除账号 ──► 二次确认 ──► 重认证 ──► 清数据 ──► 注销
```

| 步骤 | 状态 | 备注 |
|---|---|---|
| 昵称编辑 | ✅ | |
| 运动历史(本周小结 + 7 日微柱) | ✅ | 客户端聚合最近 100 条 |
| 删除账号 | ✅ | 顺序由单测锁住 |
| 「编辑形象」按钮 | 🟡→✅ | 原 toast「开发中」,本次移除 |
| 法律条款 / 举报联系方式 | ⛔ | 需隐私政策 + 用户协议 URL(待域名);本次先加「举报」入口,条款入口待 URL 就位后加 |

## 3. 页面清单(按文件)

| 页面 | 文件 | 完成度 |
|---|---|---|
| 登录 | `auth/presentation/view/login_page_view.dart` | ✅ |
| Onboarding | `profile/presentation/view/onboarding_page_view.dart` | ✅(本次去占位) |
| 房间主界面 | `room/presentation/view/room_main_view.dart` | ✅(本次加成员管理/举报) |
| 我的房间 | `room/presentation/view/my_rooms_page_view.dart` | ✅ |
| 建房 sheet | `room/presentation/view/room_create_sheet_view.dart` | ✅ |
| 编辑房间 sheet | `room/presentation/view/room_edit_sheet_view.dart` | ✅ |
| 成员管理 sheet | `room/presentation/view/room_members_sheet_view.dart` | ✅ 新增 |
| 举报 sheet | `room/presentation/view/report_sheet_view.dart` | ✅ 新增 |
| 邀请预览 sheet | `invite/presentation/view/invite_preview_sheet_view.dart` | ✅ |
| 牌库 | `action/presentation/view/card_library_page.dart` | ✅(本次去 stub) |
| 卡片详情 sheet | `action/presentation/view/card_detail_sheet_view.dart` | ✅ |
| 自建卡表单 sheet | `action/presentation/view/custom_card_form_sheet_view.dart` | ✅ |
| 牌组详情 | `action/presentation/view/deck_detail_page_view.dart` | ✅ |
| 牌组加卡 sheet | `action/presentation/view/deck_add_cards_sheet_view.dart` | ✅ |
| 运动历史 | `action/presentation/view/workout_history_page_view.dart` | ✅ |
| 我的 | `auth/presentation/view/my_page_view.dart` | ✅(本次去占位) |

## 4. 上架前仍需补的(非代码)

1. ~~App 图标与启动图~~ → 2026-10-26 已换成临时品牌版(bob 小人);正式图标待设计。
2. 隐私政策 + 用户协议页面(需要一个域名;同时托管 AASA 解锁 Universal Links)。
3. `PrivacyInfo.xcprivacy`(Firebase/Ably SDK 的 Required Reason API 声明)。
4. App Store Connect:演示账号(邮箱账号,预先进好一个有人的房间)、截图、数据收集声明。
5. Release 构建时 `--dart-define-from-file=.env` 的传递方式(Archive 脚本)。
6. 产品决议:Google 登录是否保留(Apple/Google uid 不互通)。

# CoFit 提交 App Store Connect + 开启 TestFlight 资料包

> 整理日期:2026-11-04。基准:`main` @ a81c281,Xcode 26.6,Flutter 3.41.8(fvm)。
> 用法:按 §0 → §1 → §2 → §3 的顺序走;§4 的文案直接复制进 App Store Connect;§5 是正式送审(非 TestFlight)才需要的。

---

## 0. 代码侧改动(2026-11-04 已全部落地)

| # | 项 | 改成了 | 为什么 |
|---|---|---|---|
| 0.1 | `ITSAppUsesNonExemptEncryption` | Info.plist 加 `<false/>` | 只用 HTTPS/TLS,属豁免;不加则每个 build 上传后都要在 Connect 手动回答出口合规问卷,TestFlight 才可用 |
| 0.2 | `CFBundleDisplayName` | `Cofit` → `CoFit` | 桌面图标下的名字,和品牌/商店名一致 |
| 0.3 | `TARGETED_DEVICE_FAMILY` | `1,2` → `1`(**仅 iPhone**,三个 Runner 配置) | UI 只按手机做;留 iPad 审核会在 iPad 上测,且要交 iPad 截图。以后要支持 iPad 再改回 `1,2` 并加 `UIRequiresFullScreen` |
| 0.4 | `UISupportedInterfaceOrientations` | 只留 `Portrait`;删掉 `~ipad` 那组 | 房间场景/扇形手牌没做横屏布局 |
| 0.5 | `ios/Runner/PrivacyInfo.xcprivacy` | 新增并加入 Runner 的 Copy Bundle Resources | App 级隐私清单,**与 §5.1 的 App Privacy 表必须一致**,改一处要同步另一处 |
| 0.6 | `scripts/build_ipa.sh` | 新增,固定带 `--dart-define-from-file=.env` | 忘传 → 包里没 Ably key,房间永远「未配置」 |
| 0.7 | `pubspec.yaml` 的 `description` | 一句话产品描述 | 不影响上架,顺手改 |

已经 OK、不用动的:
- 1024 图标无 alpha、尺寸正确(2026-11-05 已换成豆豆形象,源文件 `docs/brand/app_icon.svg`)。
- Bundle id `com.passerbo.cofitapp`、Team `J95TRWHWYM`、自动签名、Sign in with Apple entitlement。
- 账号删除、举报、房主踢人、登录页法律条款链接(审核 1.2 / 5.1.1(v) 的硬要求)都已实现。
- 隐私政策 / 用户协议两条 GitHub Pages 链接本次 curl 均 200。
- Deployment target 15.0;Xcode 26.6 满足「必须用 iOS 26 SDK 构建」的要求。

---

## 1. App Store Connect「新建 App」要填的

| 字段 | 值 |
|---|---|
| 平台 | iOS |
| 名称 | **CoFit**(商店名全球唯一,被占就用 `CoFit - 虚拟健身房` / `CoFit: Workout Together`) |
| 主要语言 | 简体中文(App 全部 UI 是中文) |
| 套装 ID | `com.passerbo.cofitapp`(下拉里应该已经有;没有说明 Developer 门户没注册显式 App ID,先去 Certificates, IDs & Profiles 注册并勾 Sign in with Apple) |
| SKU | `cofit-ios-001`(内部用,任意) |
| 用户访问权限 | 完全访问 |

建完 App 后在「App 信息」里补:

| 字段 | 值 |
|---|---|
| 副标题(30 字内) | `和好友一起打卡运动` |
| 类别 | 主要:健康健美(Health & Fitness);次要:社交(Social Networking) |
| 内容版权 | `© 2026 PasserBo` |
| 年龄分级 | 走新版问卷。关键答案:用户生成内容 **是**(房间名/卡名/昵称)、无聊天/私信、无不受限网页访问、无赌博/医疗/暴力。预期落在 **13+**,和隐私政策「不面向 13 岁以下」对齐 |
| 隐私政策 URL | `https://passerbo.github.io/co-fit/docs-legal-privacy/` |
| 用户协议 | 用 Apple 标准 EULA 即可;自定义条款链接可填 `https://passerbo.github.io/co-fit/docs-legal-terms/` |

---

## 2. 打包上传

### 2.1 一次性准备

1. **Xcode → Settings → Accounts 里登录拥有 `J95TRWHWYM` 团队的 Apple ID**(TestFlight 上传用 Xcode 签名即可,不需要 App Store Connect API key)。
   ⚠️ 2026-11-05 实测:本机没登录账号、也没有该团队的 Apple Distribution 证书时,归档成功但导出 ipa 报 `exportArchive No Accounts / No signing certificate "iOS Distribution" found`。登录后 `-allowProvisioningUpdates` 会自动申请 Distribution 证书与 App Store profile,不需要手动去开发者网站建。
2. `.env` 里有真实 `ABLY_API_KEY` / `ABLY_CLIENT_ID_PREFIX`(gitignored)。
3. 版本号:`pubspec.yaml` 当前 `1.0.0+3`(build 3 于 2026-11-18 上传)。**每次上传 build number 必须递增**(`+2`、`+3`…),同一 `1.0.0` 下可以传多个 build。

### 2.2 构建命令

```bash
scripts/build_ipa.sh
```

脚本等价于 `fvm flutter build ipa --release --dart-define-from-file=.env --export-options-plist=ios/ExportOptions.plist`;要覆盖版本号用 `scripts/build_ipa.sh 1.0.0 3`(build-name build-number)。导出配置在 `ios/ExportOptions.plist`(method `app-store-connect`、自动签名、上传符号)。

归档成功但导出失败(签名问题)时,修好签名后**只导出、不重编**:

```bash
scripts/export_ipa.sh
```

产物:`build/ios/ipa/*.ipa`(同时生成 `build/ios/archive/Runner.xcarchive`)。

> 第一次跑可能报「No signing certificate / provisioning profile」:用 Xcode 打开 `ios/Runner.xcworkspace` → Runner target → Signing & Capabilities 勾 Automatically manage signing、选 Team,Xcode 会自动创建 App Store 分发 profile,再重跑上面命令。
> 如果 `flutter clean` 过:先 `fvm flutter build ios --config-only`,再 `cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install`(CLAUDE.md 的既有坑)。

### 2.3 上传(三选一)

- **Transporter.app**(Mac App Store 免费):拖 `build/ios/ipa/*.ipa` → Deliver。最省事。
- Xcode Organizer:`open build/ios/archive/Runner.xcarchive` → Distribute App → App Store Connect → Upload。
- **命令行(推荐)**:`scripts/upload_testflight.sh` —— 用 App Store Connect API key 对现有归档做云签名并 `-exportArchive` 到 `destination: upload`,不依赖 Xcode 登录态(2026-11-12 实测:Xcode 已登录但 xcodebuild 仍报 `Failed to Use Accounts`,API key 路径可用)。配置 `~/.config/cofit-release/config.json` `{ "keyId", "issuerId" }`,私钥 `~/.appstoreconnect/private_keys/AuthKey_<keyId>.p8`;与 GeoGhost 共用同一团队 `J95TRWHWYM` 的发布 key(App Manager 角色)。
- 命令行(API key):`xcrun altool --upload-app -f build/ios/ipa/<name>.ipa -t ios --apiKey <KEY_ID> --apiIssuer <ISSUER>`(要先在 Connect → Users and Access → Integrations 建 API key)。

上传后 10–30 分钟处理完,Connect → TestFlight 页会出现 build;若 0.1 没加,这里会卡在「缺少出口合规信息」,点进去选「否,不使用非豁免加密」。

---

## 3. 开启 TestFlight

### 3.1 内部测试(不需要审核,传完即测)

1. TestFlight → 内部测试 → `+` 建组(如 `Core`),勾「自动分发新 build」。
2. 添加测试员:必须先在 **Users and Access** 里把对方加进团队(Developer / App Manager 角色都行),上限 100 人。
3. 对方装 TestFlight app,收邮件接受即可。

### 3.2 外部测试(第一个 build 要过 Beta App Review,通常 1 天内)

1. TestFlight → 外部测试 → `+` 建组(如 `Friends`),可开「公开链接」让人扫码加入(上限 10,000)。
2. 填「测试信息」(§4.1)和「Beta App 审核信息」(§4.2)。
3. 把 build 加进组 → 提交审核。

### 3.3 测试账号准备(Beta App Review 和正式审核都要)

2026-11-19 已建好,脚本 `scripts/seed_review_account.py`(可重复执行):

- **演示账号**:邮箱密码账号 `review.cofit@example.com`,昵称 `Reviewer`(已完成起名,登录直接进主界面)。`example.com` 是保留域名,收不到信,审核也不需要收信。**密码只在 `keys/review_account.json`**(gitignored,权限 600),从那里复制到 App Store Connect。
- **测试房间**:`Review Room`,演示账号是房主,登录后直接看到这个房间;牌组由 App 首次登录时自动生成默认牌组,不需要预置。
- **数据怎么写的**:脚本走 Firebase 客户端 REST 接口,以演示账号自己的身份写 Firestore,和 App 一样受 rules 约束,不需要 service account。房间格式与 `create_room_usecase.dart` 一致,邀请链接可用(脚本会打印)。
- **账号被删了怎么办**:审核员若用演示账号试「删除账号」,数据会被清空;再跑一次脚本即可重建同一邮箱、同一密码的账号和新房间。
- 房间里别人的小人只在对方在线时出现。审核期间想让审核员看到实时状态,用另一台设备登录自己的账号,通过房间右上 ⋯ → 邀请好友加入 `Review Room` 并保持在线;做不到也没关系,登录前的演示房间已经展示了多人小人和打牌。
- Sign in with Apple 审核员会用自己的 Apple ID 试,不用准备。Google 登录按钮由 Remote Config 默认关,审核看不到,不用准备。

---

## 4. 可直接复制的文案

### 4.1 TestFlight「测试信息」

**Beta App 描述**(主语言简体中文;外部测试者和 Beta 审核都会看):
```
CoFit 是一座「虚拟健身房」:你和好友以小人形象出现在同一个房间里,实时看到谁在运动、在做什么动作。从底部手牌里上滑打出一张动作卡就开始运动,倒计时结束自动记入运动历史。

第一次打开时会先进入一个演示房间,不用登录就能看到自己的小人、几个「示例」小人,并亲手打出一张卡;之后再用 Apple 或邮箱登录,建房间、邀请好友一起练。

本轮想听到的反馈:演示房间是否让你明白这个 App 怎么玩、和好友在同一房间运动的感觉、打牌与倒计时是否顺手、遇到的任何卡顿或报错。
```

英文版(若 Test Information 加了英文本地化):
```
CoFit is a "virtual gym": you and your friends appear as avatars in a shared room and see who is working out, and what they are doing, in real time. Swipe up a card from your hand to start an exercise; when the countdown ends it is saved to your workout history.

On first launch you enter a demo room without signing in: you see your own avatar and a few sample avatars, and play a card yourself. Then sign in with Apple or email, create a room and invite friends to work out together.

Feedback we are looking for: whether the demo room explains how the app works, how it feels to work out in the same room as friends, whether playing cards and the countdown feel smooth, and any lag or errors you hit.
```

**反馈邮箱**:填你的邮箱。**营销 URL**:可空。**隐私政策 URL**:`https://passerbo.github.io/co-fit/docs-legal-privacy/`。

**What to Test**(每个 build 可改;只写一个账号就能测完的步骤,Beta 审核员只有演示账号):
```
v1.0.0 (6)
本次新增:今日进度(每天的目标与进度)、做完一张卡后记一句感受(运动 memo)、卡片标明「做多少」;伙伴开始运动时的推送通知。
1. 首次打开:在演示房间里打出一张卡,看小人做动作;倒计时结束后点「登录,把好友叫进来」(也可以右上「跳过」)
2. 用邮箱或 Apple 登录;新账号会先起名
3. 「我的 → 发现公开房间」:列表里已有几个公开房间,用搜索框按房间名或简介搜索;点开一个房间,点「加入并进入」。进房后会弹出「伙伴开始运动时通知你?」,点「打开通知」后再出现系统的通知权限请求
4. 「我的 → 新建房间」:填房间名,可见性选「公开」,点「创建并进入」;弹出的分享卡可以复制邀请链接;关掉分享卡后(如果第 3 步没回答)也会询问通知
5. 进入房间后,下半部分是「今日面板」:最上方「今日进度」显示今天完成几张 / 目标几张,右侧按钮可以改目标;「今日推荐」点一下,面板收起并停在推荐的卡上
6. 上滑中间那张卡开始运动(有的卡片上写着建议做多少:次数 / 重量 / 距离等);小人做动作、倒计时走完后回到待机
7. 做完后面板最上方出现「刚才这张」:点一个感受,也可以写一句话(都可以跳过);今日进度跟着加一
8. 运动中把 App 切到后台或杀掉再打开,倒计时是否接着走
9. 「我的 → 运动 → 累计时长」进入运动历史,能看到刚才的记录和写的感受,点一行可以修改或删除
10. 「我的 → 通知」:可以关掉「伙伴开始运动时通知我」;房间右上「⋯」里可以「静音通知」这个房间
11. 「我的」页底部「删除账号」能走通(会清空该账号全部数据)
有第二台设备的话可以额外试:把邀请链接发过去加入同一房间,两边都允许通知;一方把 App 切到后台或锁屏,另一方开始一张卡,应收到「你的「房间名」运动伙伴 昵称 开始运动了!」,点开会进到那个房间。同一个人 3 小时内最多收到一条。
已知问题:没装 App 的人点邀请链接不会跳 App Store(本期无 Universal Links);形象自定义尚未开放。
```

### 4.2 Beta App 审核信息 / App 审核信息(英文,审核员看)

| 字段 | 值 |
|---|---|
| 联系人 | 你的姓名 / 电话 / 邮箱 |
| 需要登录 | **是** |
| 演示账号 | `review.cofit@example.com` / 密码见 `keys/review_account.json`(§3.3) |
| 备注 | 见下 |

```
CoFit is a social fitness app: friends appear as avatars in a shared "virtual gym" room and see each other's live workout status. Users start a workout by playing an exercise card from their hand. The UI is in Simplified Chinese.

How to test:
1. On first launch a demo room opens before sign-in (no network or account needed). Tap the cards at the bottom, then swipe up the center card to start a short 10-second demo workout. Tap "跳过" (Skip, top right) or the button "登录,把好友叫进来" (Sign in) to continue. The demo is shown only once per install.
2. On the sign-in screen tap "使用邮箱登录" (Sign in with email) and use the demo account above. You can also use Sign in with Apple.
3. The demo account owns a room named "Review Room". Members who are not online stay in the room as dimmed avatars labelled "离线" (Offline); live workout status is shown only for members who are online. The demo room in step 1 shows what a room with several active people looks like. Optionally, sign in on a second device with Sign in with Apple and join via the invite link (⋯ at top right → 邀请好友 / Invite) to see live status.
4. To create a room: tab "我的" (Me) → "新建房间" (New room), enter a name, choose "公开" (Public) and tap "创建并进入" (Create and enter). To browse rooms: tab "我的" (Me) → "发现公开房间" (Discover public rooms). A few public rooms already exist; search by name or description, tap a room and then "加入并进入" (Join and enter).
5. When you enter a room, the lower half of the screen is a panel ("今日面板", Today panel) and your own avatar stands on its top edge. Tap your avatar, or tap or drag down the handle at the top of the panel, to collapse it; the hand of cards then appears at the bottom. Tapping "今日推荐" (Today's pick) in the panel also collapses it and opens the hand on the suggested card. Tap your avatar again to reopen the panel. With the panel collapsed, tap the fanned cards and swipe up a card to start a workout; a countdown runs and the workout is logged in Workout History: tab "我的" (Me) → row "累计时长" (Total time) under "运动" (Workout).
6. Room owner tools (⋯ at top right): invite via link, manage/remove members, mute notifications for this room, report, disband. Members can report a room or member and mute the room.
7. Push notifications: after joining or creating a room, an in-app sheet ("伙伴开始运动时通知你?", Notify you when a friend starts a workout?) explains the purpose first; the system permission dialog appears only after tapping "打开通知" (Turn on notifications). When a friend in the same room starts a workout, the other members receive one notification (at most one per person every 3 hours). Users can turn this off in tab "我的" (Me) → "通知" (Notifications), or mute a single room from its ⋯ menu. Receiving a notification needs a second account in the same room.
8. Account deletion: tab "我的" (Me) → "删除账号" (Delete Account) at the bottom removes all user data and revokes the Apple credential. Please test deletion with a Sign in with Apple account if possible, so the demo account stays available for other reviewers.

Notes:
- No HealthKit, location, camera, photos, or ads are used. Push notifications are used only for the feature in step 7 (no marketing notifications).
- The sample avatars in the demo room are labelled "示例" (Sample); they are not real users and nothing in the demo is uploaded.
- Google Sign-In exists in code but is disabled by a remote feature flag; only Sign in with Apple and email/password are visible.
- Invite deep links use the custom scheme cofit://; Universal Links are not implemented in this version.
```

---

## 5. 正式提交 App Store 才需要的(TestFlight 不需要)

### 5.1 App Privacy(数据收集声明)

先回答「是否收集数据」→ **是**。逐项:

| Apple 数据类型 | 收集? | 关联到用户身份 | 用于追踪 | 用途 | 来源 |
|---|---|---|---|---|---|
| 联系信息 → 电子邮件地址 | 是 | 是 | 否 | App 功能 | Firebase Auth(邮箱登录 / Apple 中继邮箱) |
| 标识符 → 用户 ID | 是 | 是 | 否 | App 功能 | Firebase uid + **昵称**(Apple 定义里 screen name / handle 属 User ID,不是 Name),Ably presence 带 userId |
| 健康与健身 → 健身 | 是 | 是 | 否 | App 功能 | `users/{uid}/sessions` 运动记录 |
| 用户内容 → 其他用户内容 | 是 | 是 | 否 | App 功能 | 房间名/描述、自建卡、牌组、举报内容 |
| 设备 ID / 位置 / 联系人 / 照片 / 诊断 / 使用数据 / 广告数据 | 否 | — | — | — | 无 Analytics、Crashlytics、广告 SDK |
| 联系信息 → 姓名 | **否** | — | — | — | Apple 登录虽请求 `fullName` scope,但返回的姓名未读取、未上传;昵称归 User ID。⚠️ 若将来打开 Google 登录,Firebase Auth 会自动存 Google 账号的真实姓名到 `displayName`,届时要改为「是」 |

- 「是否用于追踪」全部 **否**,所以不会触发 ATT。
- Firebase Remote Config 取参时带 OS 版本/国家/语言做定向,Firebase 文档未归入任何需申报类型,且不关联用户,按 Apple「仅用于功能、不存储、不关联」豁免处理,不申报。
- 这张表和 §0.6 的 `PrivacyInfo.xcprivacy` 必须保持一致;隐私政策 §1 已逐条对应。

### 5.2 截图

- 必交:**6.9 英寸 iPhone**(iPhone 17 Pro Max / 16 Pro Max 模拟器,1320×2868),3–10 张。6.5 英寸可由 6.9 自动缩放。
- 已改为仅 iPhone,不需要 iPad 截图。
- 建议 5 张:房间场景(多个小人在线)/ 扇形手牌聚焦 / 打卡倒计时 HUD / 牌库 / 运动历史。多个小人在线的画面可以直接用登录前的演示房间截。
- 命令:booted 模拟器 `xcrun simctl io booted screenshot room.png`;iPhone 17 Pro 模拟器出的是 6.3 英寸尺寸,**需要换 Pro Max 模拟器**。

### 5.3 商店文案

**宣传文本(170 字,可随时改)**:
```
一个人练不动?把好友拉进同一个虚拟健身房,看见彼此在动,打一张卡就开始。
```

**描述**:
```
CoFit 是一座「虚拟健身房」。

你和好友以小人形象出现在同一个房间里,谁在运动、在做什么动作,实时可见。不用约时间、不用开摄像头,打开 App 就能感受到「有人陪着练」。

· 房间:新建或通过邀请链接加入,左右滑动切换多个房间
· 动作卡:从手牌里打出一张卡(深蹲、平板支撑、开合跳……)即开始计时,结束自动记录
· 牌库:官方动作卡 + 自建卡,自由组成牌组
· 运动历史:每次打卡都有记录与统计
· 实时状态:运动中 / 暂停 / 挂机,房间里一眼看清

支持 Apple 登录与邮箱登录,可随时在「我的」里删除账号。
```

**关键词(100 字符,逗号分隔)**:
```
健身,打卡,运动,好友,一起运动,虚拟健身房,自律,训练,计时,workout,fitness,social
```

**技术支持 URL**:`https://github.com/PasserBo/co-fit/issues`
**营销 URL**:可空。

### 5.4 审核易踩点自查

- [ ] 1.2 UGC:举报 ✅、移出成员 ✅、隐私政策里有联系方式 ✅;审核员可能问「如何屏蔽用户」—— 当前靠退出房间/房主踢人,备注里已写明。
- [ ] 2.1 无占位 UI:「形象定制即将上线」已移除;再全局 grep 一遍「即将上线 / coming soon / TODO」文案。
- [ ] 4.8 第三方登录:有 Google 登录就必须有 Sign in with Apple ✅。
- [ ] 5.1.1(v) 账号删除 ✅(App 内可直接删,不是只给链接)。
- [ ] 断网:房间页有连接状态提示条 ✅。
- [ ] 首次启动不弹任何权限(本 App 没有权限申请)✅。

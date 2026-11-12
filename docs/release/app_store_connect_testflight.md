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
3. 版本号:`pubspec.yaml` 当前 `1.0.0+2`(build 2 于 2026-11-12 上传)。**每次上传 build number 必须递增**(`+2`、`+3`…),同一 `1.0.0` 下可以传多个 build。

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
- **命令行(推荐,无需 API key)**:`scripts/upload_testflight.sh` —— 用 Xcode 已登录账号把现有归档 `-exportArchive` 到 `destination: upload`,等价于 Organizer 的 Upload。
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

- 在 Firebase Auth 建一个**邮箱密码账号**:`review@…`(用你能收信的邮箱),密码记在 `keys/` 目录(gitignored)。
- 用这个账号登录一次,起好昵称,**提前加入一个已有 2–3 个成员的房间**,并让其中一个成员保持在线/运动中,审核员打开就能看到小人和状态——否则 App 的核心卖点是空的。
- 房间里预置一个有卡的牌组,让审核员能直接打牌。
- Sign in with Apple 审核员会用自己的 Apple ID 试,不用准备。Google 登录按钮由 Remote Config 默认关,审核看不到,不用准备。

---

## 4. 可直接复制的文案

### 4.1 TestFlight「测试信息」

**Beta App 描述**(中文版,给自己人):
```
CoFit 是一个「虚拟健身房」:你和好友以小人形象出现在同一个房间里,实时看到谁在运动、在做什么。从手牌里打出一张动作卡就开始运动,倒计时结束自动记录。

本轮重点测试:登录 → 起名 → 新建/加入房间 → 邀请好友 → 打牌运动 → 运动历史 → 删除账号。
```

**反馈邮箱**:填你的邮箱。**营销 URL**:可空。

**What to Test**(每个 build 可改):
```
v1.0.0 (build 1) 首个 TestFlight 版本
1. 用 Apple 登录或邮箱注册,完成起名
2. 新建房间 → 右上 ⋯ → 邀请好友,把链接发给另一台设备
3. 两台设备同时在房间里,打出一张卡,确认对方能看到你的运动状态变化
4. App 切后台/被杀后重开,倒计时是否恢复
5. 「我的 → 运动历史」有记录
6. 「我的 → 删除账号」能走通
已知问题:没装 App 的人点邀请链接不会跳 App Store(本期无 Universal Links);形象自定义尚未开放。
```

### 4.2 Beta App 审核信息 / App 审核信息(英文,审核员看)

| 字段 | 值 |
|---|---|
| 联系人 | 你的姓名 / 电话 / 邮箱 |
| 需要登录 | **是** |
| 演示账号 | `review@…` / 密码(§3.3) |
| 备注 | 见下 |

```
CoFit is a social fitness app: friends appear as avatars in a shared "virtual gym" room and see each other's live workout status. Users start a workout by playing an exercise card from their deck.

How to test:
1. Sign in with the demo account (email/password above) or with Sign in with Apple.
2. You will land in a room that already has other members. One member is kept online during the review window so you can see live status.
3. Tap the fanned cards at the bottom, swipe up a card to start a workout; a countdown runs and the workout is logged under "我的 → 运动历史" (Me → Workout History).
4. Room owner tools (⋯ at top right): invite via link, manage/remove members, report, disband. Members can report a room or member.
5. Account deletion: "我的 → 删除账号" (Me → Delete Account) removes all user data and revokes the Apple credential.

Notes:
- No HealthKit, location, camera, photos, push notifications, or ads are used.
- Google Sign-In button exists in code but is disabled by a remote feature flag; only Sign in with Apple and email/password are visible.
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
- 建议 5 张:房间场景(多个小人在线)/ 扇形手牌聚焦 / 打卡倒计时 HUD / 牌库 / 运动历史。用 §3.3 的预置房间来截。
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

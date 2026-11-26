# Tasks: add-usage-analytics

## Now
2026-11-26:M1 代码完成(未提交):Firebase Analytics 接入 + 推送相关事件 + 出牌 / 完成;隐私政策、PrivacyInfo、ASC 隐私表说明已改。等用户确认隐私政策文字后提交;ASC 的 App Privacy 表由用户在网页上改(T5)。M2(今日面板事件)未开始。

## M1 · 接入与推送事件
- [x] T1 加 `firebase_analytics`;`lib/core/analytics/`(tracker 接口、Firebase 实现、no-op、事件名表)— owner: agent · done 2026-11-26
  - evidence: analyze 无问题;单测环境自动 no-op,全量测试通过
- [x] T2 事件:`push_offer_shown` / `push_offer_result` / `push_permission_result` / `push_opened` / `push_setting_changed` / `room_push_muted` / `card_started` / `card_completed` — owner: agent · done 2026-11-26
- [x] T3 Info.plist 关掉 ad storage / ad user data / ad personalization / IDFV / 屏幕自动上报;不调用 setUserId — owner: agent · done 2026-11-26
- [x] T4 `PrivacyInfo.xcprivacy` 加 产品交互 / 设备 ID(不关联、分析);隐私政策 §1 §2 §4 §5;`docs/release` 的 App Privacy 表 — owner: agent · done 2026-11-26
- [ ] T5 App Store Connect → App 隐私:按 `docs/release/app_store_connect_testflight.md` §5.1 新增「使用数据 → 产品交互」「标识符 → 设备 ID」(都不关联身份、不追踪、用途:分析)— owner: me · verify: 用户确认
- [ ] T6 Firebase console → Analytics → DebugView 或 Realtime 里看到事件(真机或 TestFlight 包)— owner: me · verify: 截图 / 口头确认
- [ ] T7 GA4 里建一个漏斗:`push_opened` → 30 分钟内 `card_started` — owner: me · after: T6
- [x] T9 事件表 `docs/analytics/events.md`(事件、参数、屏幕 ID、常用分析)— owner: agent · done 2026-11-26

## M2 · 今日面板
- [ ] T8 面板展开 / 收起、模块点击、从推荐出牌 — owner: agent

# CoFit 使用数据事件表(Firebase Analytics)

> 事件、参数与屏幕 ID 的唯一登记处。**新增或修改任何事件,先改这里,再改代码**(`lib/core/analytics/analytics_events.dart`)。
> 相关 change:[add-usage-analytics](../spec/changes/add-usage-analytics/proposal.md)

## 规则

- **命名**:小写 + 下划线,`<对象>_<动作>`(`card_started`、`push_opened`)。事件名 ≤ 40 字符,参数名 ≤ 40 字符,字符串参数值 ≤ 100 字符(GA4 限制)。
- **只加不改**:事件名、参数名、参数取值一旦上线就不再改名(改名会把历史数据切成两段)。不再使用的事件标「停用」并写日期,不删行。
- **布尔一律用 1 / 0**(GA4 参数不支持布尔)。
- **不上报**:用户 id、昵称、邮箱、房间名、卡片名、memo 内容等任何可识别个人或用户内容的值。房间 id 也不上报。
- **保留的名字**不能用:`first_open`、`session_start`、`screen_view`、`app_*`、`firebase_*`、`ga_*` 等 Firebase 自动事件 / 前缀。
- 新事件要在 GA4 里当作「自定义维度」使用的参数,上线后到 Firebase console → Analytics → 自定义定义 里登记(见下方各表「需登记维度」列)。

## 事件

### 通知询问与权限(add-partner-start-push)

| 事件 | 什么时候发 | 参数 | 代码位置 | 加入版本 |
|---|---|---|---|---|
| `push_offer_shown` | App 内通知提示出现(加入 / 新建房间后,或老用户打开 App) | `trigger` | `notification/presentation/push_lifecycle_binder.dart` | 1.0.0 (7) |
| `push_offer_result` | 用户在 App 内提示里做出选择 | `trigger`、`accepted` | 同上 | 1.0.0 (7) |
| `push_permission_result` | 系统通知权限请求有了结果 | `source`、`result` | 同上(source=offer);`auth/presentation/view/my_page_view.dart`(source=settings) | 1.0.0 (7) |
| `push_opened` | 点开「伙伴开始运动」的推送(冷启动或从后台) | `entered_room` | `push_lifecycle_binder.dart` | 1.0.0 (7) |
| `push_setting_changed` | 「我的 → 通知」里切换总开关 | `enabled` | `my_page_view.dart` | 1.0.0 (7) |
| `room_push_muted` | 房间菜单里静音 / 取消静音 | `muted` | `room/presentation/view/room_main_view.dart` | 1.0.0 (7) |

### 运动

| 事件 | 什么时候发 | 参数 | 代码位置 | 加入版本 |
|---|---|---|---|---|
| `card_started` | 在房间里开始一张卡(不含登录前的演示房间) | `duration_sec` | `action/provider/own_action_session_notifier.dart` `play` | 1.0.0 (7) |
| `card_completed` | 一张卡倒计时结束(不含被结束后补记的) | `duration_sec` | 同上 `complete` | 1.0.0 (7) |

## 参数

| 参数 | 类型 | 取值 | 含义 | 需登记维度 |
|---|---|---|---|---|
| `trigger` | 字符串 | `join` / `create` / `existing_member` | 通知提示出现的时机:加入房间后 / 新建房间后 / 更新前就在有人房间里的用户打开 App | 是 |
| `accepted` | 数字 | 1 / 0 | 在提示里点了「打开通知」/「以后再说」(或关掉) | 是 |
| `source` | 字符串 | `offer` / `settings` | 系统权限请求来自 App 内提示 / 「我的」里的开关 | 是 |
| `result` | 字符串 | `granted` / `denied` | 系统权限结果(临时授权算 granted) | 是 |
| `entered_room` | 数字 | 1 / 0 | 点开推送后是否切进了那个房间(0 = 已不在该房间) | 否 |
| `enabled` | 数字 | 1 / 0 | 总开关打开 / 关闭 | 否 |
| `muted` | 数字 | 1 / 0 | 静音 / 取消静音 | 否 |
| `duration_sec` | 数字 | 卡片时长(秒) | 卡片的设定时长 | 否(数值指标) |

## 屏幕 ID

**目前不上报屏幕。** Firebase 的自动屏幕上报已关闭(`Info.plist` `FirebaseAutomaticScreenReportingEnabled = NO`):Flutter 在 iOS 上只有一个原生页面,自动上报只会得到无意义的 `FlutterViewController`。

以后要上报时,用 `screen_view` + 下面的 `screen_name`,并在这里登记:

| screen_name | 页面 | 代码 |
|---|---|---|
| (待定) | | |

命名规则:小写 + 下划线,按用户看到的页面命名(`room`、`card_library`、`my_page`、`workout_history`),弹层用 `<页面>__<弹层>`(`room__actions_sheet`)。

## 常用分析

- **通知同意率**:`push_offer_result`(accepted=1)/ `push_offer_shown`,按 `trigger` 拆分。
- **系统授权率**:`push_permission_result`(result=granted)/ 全部,按 `source` 拆分。
- **推送带动出牌**:漏斗 `push_opened` → `card_started`,时间窗 30 分钟。
- **关掉通知的比例**:`push_setting_changed`(enabled=0)与 `room_push_muted`(muted=1)。

## 变更记录

- 2026-11-26:建表;通知询问与权限 6 个事件、运动 2 个事件(add-usage-analytics M1,预计随 1.0.0 (7) 上线)。

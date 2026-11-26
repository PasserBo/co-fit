# Proposal: 接入使用数据统计(Firebase Analytics)——先看推送有没有用,再比较今日面板布局

> State: accepted · Updated: 2026-11-26

## Intent

App 目前没有任何使用数据统计,改了东西看不出效果:
- 伙伴开始运动推送(`add-partner-start-push`)的冷却时长、文案、询问时机都是可调的内容,但不知道有多少人同意通知、推送被点开的比例、点开后有没有出牌。
- 今日面板(`add-home-sheet`)的模块组成和顺序可以远程调整,但无法知道打开 App 后出第一张卡的比例与耗时、各模块的点击率、没人在线时的出牌率。

## Scope

In scope:
- M1(本次):接入统计;记录通知询问的展示与选择、系统权限结果、推送被点开、通知开关与房间静音、出牌与完成。
- M2:今日面板的展开 / 收起、模块点击。
- 隐私政策、App 内隐私清单、App Store 隐私表三处同步说明使用数据统计。
Out of scope:
- 广告、跨 App 追踪、用户画像;不收集广告标识符。
- 把统计和账号关联(不上报用户 id)。
- 服务端事件:推送发出数量看 Functions 日志。

## Decisions
- 2026-11-21: 不阻塞 `add-home-sheet`,单独开这个 change — 用户决定:先把面板做出来。

- 2026-11-26: 用 Firebase Analytics,先做推送相关的数据 — 用户决定;推送的冷却、文案、询问时机要靠数据调。
- 2026-11-26: 不上报用户 id、不收集广告标识符,统计不与账号关联 — agent 的默认做法(隐私表可以填「不关联身份」),用户未确认。

## Open questions
- (无阻塞项)上线前隐私政策、App 内隐私清单与 App Store 隐私表必须三处一致(App Store 那一处由用户填)。

## Links
- 相关: `add-partner-start-push`(M1 的事件)、`add-home-sheet`(M2 的事件)

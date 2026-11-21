# Proposal: 接入使用数据统计,用来比较今日面板的不同布局

> State: idea · Updated: 2026-11-21

## Intent

今日面板(`add-home-sheet`)的模块组成和顺序可以远程调整,目的是测试用户更愿意在首屏看到什么。但 App 目前没有任何使用数据统计,调了布局也看不出效果:无法知道打开 App 后出第一张卡的比例与耗时、各模块的点击率、没人在线时的出牌率。

## Scope

In scope:
- 记录足以比较布局的少量使用数据(打开、面板展开 / 收起、模块点击、出牌、完成)。
Out of scope:
- 广告、跨 App 追踪、用户画像。

## Decisions
- 2026-11-21: 不阻塞 `add-home-sheet`,单独开这个 change — 用户决定:先把面板做出来。

## Open questions
- 用哪种统计方式(自建最小记录 / 第三方服务)?
- 上线前必须同步隐私政策、App 内隐私清单与 App Store 的隐私表,三处一致。

## Links
- 依赖: `add-home-sheet`

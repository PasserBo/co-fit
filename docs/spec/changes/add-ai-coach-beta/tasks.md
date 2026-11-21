# Tasks: add-ai-coach-beta

## Now
M1 完成(离线回放测试 + analyze + 全量测试 + 模拟器构建)。下一步 T6(me):在 Firebase console 启用 AI Logic,之后 agent 在模拟器上跑 T7。
注意:system prompt 约 45k 字符(A2UI 基础组件目录占绝大部分),每次请求都发——T8 评估费用/延迟时考虑裁剪组件目录。

## M1 · 集成与日志(离线可测)
- [x] T1 加依赖(a2ui_flutter/core/agent、firebase_ai 4.x、path_provider、flutter_markdown_plus)— owner: agent · verify: `fvm flutter pub get` 成功 · done 2026-11-18
  - evidence: pub get 成功:a2ui_flutter 0.4.0 / a2ui_core 0.8.0 / a2ui_agent 0.4.0 / firebase_ai 4.0.0
- [x] T2 `ai_coach` feature:模型接口 + firebase_ai 实现 + 会话循环 + 记录上下文 usecase — owner: agent · after: T1 · verify: 单测(上下文格式、回放一轮表单往返) · done 2026-11-18
  - evidence: test/features/ai_coach/usecase/build_coach_context_usecase_test.dart、provider/coach_chat_controller_test.dart(官方录制的表单往返回放)
- [x] T3 JSONL 会话日志 + 汇总脚本 `tool/summarize_ai_coach_log.dart` — owner: agent · after: T2 · verify: 单测断言事件序列;脚本对测试产出的日志可跑 · done 2026-11-18
  - evidence: coach_chat_controller_test 断言事件序列;JSONL 重复 close 截断问题已修并有回归断言;`fvm dart run tool/summarize_ai_coach_log.dart` 对回放生成的日志输出汇总表
- [x] T4 教练页(同意说明、预置问题、输入、卡片渲染、导出日志)+ 运动历史页入口 + 开关 — owner: agent · after: T2 · verify: widget test(无开关不显示入口、同意前不可提问、回放渲染卡片) · done 2026-11-18
  - evidence: test/features/ai_coach/presentation/ai_coach_page_view_test.dart(开关关无入口 / 同意前不可提问且返回不发请求 / 同意后预置问题渲染卡片 / 再进入不再询问且对话清空)
- [x] T5 `flutter analyze` 零新增告警、全量 `flutter test` 通过、iOS 模拟器构建通过 — owner: agent · after: T1–T4 · verify: 命令输出 · done 2026-11-18
  - evidence: `fvm flutter analyze` No issues;`fvm flutter test` 247+ 全过;`flutter build ios --simulator --debug` ✓ Built Runner.app(新插件经 SPM,Package.resolved 有变化)

## M2 · 真模型试用
- [ ] T6 在 Firebase console(项目 cofit-lmdyd)→ AI Logic → Get started → 选 **Gemini Developer API**(免费档)启用 — owner: me · verify: console 显示已启用;告诉 agent 一声
- [ ] T7 模拟器 debug 构建里走一遍 4 条预置问题 + 一次卡片提交,导出日志 — owner: agent(模拟器)/ me(看效果) · after: T5, T6 · verify: 日志汇总表 + 截图
- [ ] T8 根据日志写试用结论(延迟、首卡时间、渲染错误率、观感),记入 proposal Decisions — owner: agent · after: T7 · verify: 用户确认

## M3 · 开放给测试者前(按需)
- [ ] T9 更新隐私政策 / PrivacyInfo.xcprivacy / App Store Connect App Privacy(新增「健身数据 → 第三方 AI 处理」)— owner: me · verify: 三处一致
- [ ] T10 启用 App Check(App Attest)并在 AI Logic 开启强制 — owner: me + agent · verify: 真机调用成功
- [ ] T11 Remote Config 新建布尔参数 `beta_ai_coach_enabled` 并按测试者条件发布 — owner: me · after: T9, T10 · verify: 测试者能看到入口

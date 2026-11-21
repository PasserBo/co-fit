# Design: add-ai-coach-beta

## 依赖

| 包 | 版本 | 用途 |
|---|---|---|
| `a2ui_flutter` | ^0.4.0 | `MessageProcessor` + `A2uiSurface` 渲染,`basicCatalog()` |
| `a2ui_core` | ^0.8.0 | 协议消息类型 |
| `a2ui_agent` | ^0.4.0 | `A2uiGenerator` 生成 system prompt 片段;`ResponseStream` 把流式回复解析成文本 + A2UI 消息 |
| `firebase_ai` | ^4.0.0 | Firebase AI Logic(Gemini Developer API)。**5.x 需要 firebase_core 5 / Flutter 3.44**,故锁 4.x |
| `path_provider` | ^2.1.6 | 日志目录 |
| `flutter_markdown_plus` | ^1.0.12 | 模型文本 + Text 组件内的 Markdown |

`firebase_ai` 会带入 `firebase_app_check`(未启用 App Check,见风险)。

## 模块(`lib/features/ai_coach/`)

```
domain/coach_model_client.dart            # 接口:Stream<String> generate(systemPrompt, turns)
domain/entity/coach_turn.dart             # (fromUser, text)
domain/coach_session_log.dart             # 日志接口(写事件)
data/firebase_ai_coach_model_client.dart  # firebase_ai 实现
data/jsonl_coach_session_log.dart         # JSONL 文件实现 + dart:developer 镜像
usecase/build_coach_context_usecase.dart  # ActionSessionRecord 列表 → 紧凑上下文文本
provider/ai_coach_providers.dart          # 开关、client、log、同意状态
provider/coach_chat_controller.dart       # 会话循环(ChangeNotifier,改写自官方 example 的 ChatSession)
presentation/view/ai_coach_page_view.dart
presentation/widget/coach_chat_entry.dart # 纯展示:气泡/卡片/错误
```

会话循环沿用官方 example 的做法:每轮 `A2uiRequestProcessor.openStream(state)` → `feed(chunk)` → `TextPart`
显示文本、`A2uiPart` 交给 `MessageProcessor`;卡片 action 经 `outboundListener` 作为下一轮用户发言(JSON,
附 `a2uiRendererDataModel`);渲染错误以 v1.0 `error` 消息回给模型,连续最多 2 轮。

## 发给模型的数据

system prompt = 教练指令 + 运动记录上下文 + A2UI prompt 片段。记录上下文每条一行:
`YYYY-MM-DD HH:mm | templateName | actionKey | durationSec`,最多 100 条(`recentSessionsProvider` 同源),
不含 uid / roomId / sessionId。今天的日期一起给出,便于「本周」类问题。

## 日志(JSONL)

路径:`<App Documents>/ai_coach_logs/coach_<timestamp>.jsonl`,一会话一文件;同时 `developer.log(name: 'ai_coach')`。
每行 `{seq, ts, t_ms, event, ...}`:

| event | 字段 |
|---|---|
| `session_start` | model, format, protocol, catalog, packages, records |
| `system_prompt` | chars, text |
| `user_turn` | turn, kind(typed/preset/action/error), chars, text |
| `model_chunk` | turn, i, dt_ms, text |
| `model_reply` | turn, ok, error?, ttfb_ms, first_a2ui_ms, total_ms, chunks, chars, text_chars, a2ui_messages, text |
| `a2ui_message` | turn, type, surface, dt_ms, message |
| `surface_created` / `surface_deleted` | turn, surface, metadata? |
| `outbound` | type, message |
| `stream_rejected` / `processor_rejected` / `renderer_error` | turn, code, surface, path, message |
| `session_end` | turns |

汇总:`fvm dart run tool/summarize_ai_coach_log.dart <log>...`(每轮 ttfb / 首卡时间 / 总耗时 / 字数 / 错误)。
导出:`share_plus` 分享文件。日志含用户提问与运动记录,**只在设备上,不自动上传**。

### 取日志

- 真机/TestFlight:教练页右上角「导出日志」→ 系统分享(AirDrop / 存到文件)。
- 模拟器:`open "$(xcrun simctl get_app_container booted com.passerbo.cofitapp data)/Documents/ai_coach_logs"`
- 实时:`flutter run` 控制台 / DevTools Logging 里 name=`ai_coach` 的条目。
- 回放:`ReplayCoachModelClient.fromLog(File(...))` 把日志里的 `model_chunk` 原样喂回渲染器(不花模型调用),
  可用于把一次真实会话固化成测试。

### 观察到的事实

- system prompt ≈ 45k 字符,绝大部分是 A2UI 基础组件目录的说明(`A2uiGenerator.promptSnippet`),每次请求都会带上。
  `a2ui_agent` 提供 catalog pruning(`catalog_transformers/pruning.dart`),若费用/延迟不理想可裁掉用不到的组件。

## 开关

`FeatureFlags.betaAiCoachEnabled`(Remote Config `beta_ai_coach_enabled`,默认 false)。
入口可见 = `kDebugMode || betaAiCoachEnabled`。同意状态:`shared_preferences` 键 `cofit.ai_coach_consent.v1`。
可用 `--dart-define=AI_COACH_MODEL=<model>` / `AI_COACH_FORMAT=express` 覆盖模型与推理格式(均写入日志 `session_start`)。

## 风险 / 上线前

- **隐私**:运动记录与提问发送给 Google(Gemini)。开放给 TestFlight 外部测试者/正式用户前,必须同步
  `docs/legal/privacy.md`、`ios/Runner/PrivacyInfo.xcprivacy` 与 App Store Connect App Privacy(三处一致)。
- **滥用/费用**:未启用 App Check,任何拿到 Firebase 配置的人都能调用;beta 期仅内部使用可接受,开放前启用 App Check。
- `a2ui_*` 0.x,API 可能破坏性变更;版本锁在 pubspec,升级时重跑测试。

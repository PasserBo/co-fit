# CoFit 规格系统(一屏说明)

> 规则的唯一权威在 `solo-spec` skill(`~/.claude/skills/solo-spec/SKILL.md`),本文只是给人看的摘要。
> ⚠️ `docs/` 整目录随 main 推送由 GitSpec 发布到 GitHub Pages,**本目录下的提案与规格都是公开的**,不要写密钥、账号、未公开的商业信息。

## 目录

```
docs/spec/
├── spec.json            语言 zh-Hans、基线分支 main、规格里禁止出现的实现词
├── BOARD.md             所有进行中的 change:状态、下一步、谁做
├── capabilities/<能力>/
│   ├── spec.md          行为规格:只写用户能观察到的行为(Purpose + Requirements)
│   └── design.md        现在是怎么实现的(值得留的才写)
└── changes/
    ├── <change-id>/     proposal.md(为什么+范围+决议日志)/ specs/<能力>/spec.md(delta)/ design.md / tasks.md
    └── archive/YYYY-MM-DD-<change-id>/   已完成或放弃的 change,归档后不再改
```

一个能力(capability)第一次被某个 change 触碰时才建主规格,不为整个 App 回填。

## 提案状态

`idea`(记下,未定)→ `accepted`(用户决定做)→ `in-progress`(开始第一个任务)→ `done`(已上线并归档)/ `dropped`(放弃,记原因)。
只有用户能把提案改成 `accepted` / `dropped`;Claude 只能改成 `in-progress` / `done`。每条决议带日期追加到 `## Decisions`,反转也是新的一行,不改旧行。

## 任务归属

- `agent`:代码、文档、测试,Claude 能做且能自己验证;每条任务写明怎么验证。
- `me`:账号、密钥、控制台、付费服务、真机、App Store Connect 等必须由用户亲手做的事;写到用户不用回头问就能做。

## 检查与归档

```bash
python3 ~/.claude/skills/solo-spec/scripts/spec_tool.py check docs/spec/capabilities/<能力>/spec.md
```

```bash
python3 ~/.claude/skills/solo-spec/scripts/spec_tool.py check-delta docs/spec/changes/<id>/specs/<能力>/spec.md --main docs/spec/capabilities/<能力>/spec.md
```

```bash
python3 ~/.claude/skills/solo-spec/scripts/spec_tool.py archive docs/spec/changes/<id> --baseline '<hash 或 #PR>' --apply
```

归档前先不带 `--apply` 跑一次看会新建/更新哪些主规格。

## 与其他文档的关系

- 规格写「用户看到什么」;怎么实现写 `design.md`;架构权威仍是 `.cursor/rules/flutter_architecture.mdc` 与 `CLAUDE.md`。
- 现状盘点 [flows_status.md](../flows_status.md) 和 UI 进度 [ui_overhaul/STATUS.md](../ui_overhaul/STATUS.md) 继续用;规格只在 change 触碰到时建立。

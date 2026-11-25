# Tasks: add-card-prescription

## Now
2026-11-25:T1–T4 的代码与测试已完成;全量 `fvm flutter test` 403 个通过,`fvm flutter analyze` 无告警。未提交、未推送。
**卡在 T5**:`firestore.rules` 给运动记录新增了两个可选字段,要用户确认 diff(与 `add-workout-memo` 的规则改动在同一个文件里,一起确认、一起推)。规则部署之前,新版 App 完成带强度或量的卡时**写运动记录会被拒绝**——所以代码不能先于规则上线。
**没验证的**:自建卡表单里选种类、填数值这一段没有自动化测试(表单依赖较多 provider),也没有在模拟器上看过;卡面多一行后在小卡(手牌)上会不会太挤没有实机确认。
数据形状:卡片 `intensityBaseline = {label?, amounts?: [{kind, value, unit}]}`;运动记录新增可选的 `intensityLabel`、`amounts`(同样的列表)。种类清单在 `CardAmountKind.all`(次数 / 重量 / 距离;没有组数——一张卡就是一组),是内容,可增减。

- [x] T1 量的数据模型(种类清单、数值 + 单位、读写、显示文字)— owner: agent · verify: 单测 · done 2026-11-25
  - evidence: `action/domain/entity/card_amount.dart`;`card_prescription_test.dart`「CardAmount」4 个用例
- [x] T2 完成时把卡上的强度与量随运动记录保存;本机快照与被结束后的补记同样带上 — owner: agent · after: T1 · verify: 单测(保存、读回、旧记录、补记)· done 2026-11-25
  - evidence: `ActionSessionRecord.intensityLabel / amounts / prescriptionText`、`PendingSessionSnapshot`、两个 usecase 与 `OwnActionSessionNotifier`;`card_prescription_test.dart`「运动记录保存当时的强度与量」4 个用例
- [x] T3 显示:卡面预览与详情多一行量;手牌 / 牌库小卡的时长后面接量;运动历史行与 memo 详情带出强度与量;自建卡表单「做多少(可选,可多选)」— owner: agent · after: T1 · verify: widget test · done 2026-11-25
  - evidence: `card_prescription_test.dart`「显示」2 个用例(卡面、历史行)。**缺**:表单与小卡没有用例
- [x] T4 官方 32 张卡补内容(`firestore/card_templates.json`)— owner: agent · verify: JSON 合法;同步脚本的必填检查不受影响 · done 2026-11-25
  - evidence: 21 张填了量,11 张按时间做的不填;推送 main 后由 `deploy-card-templates.yml` 同步(未推送)
- [ ] T5 确认 `firestore.rules` 的 diff;推送 main 后核对 `deploy-rules.yml` 与 `deploy-card-templates.yml` 都是 success — owner: me(确认)→ agent(核对)· verify: CI 输出
- [ ] T6 真机看一遍:手牌小卡是否太挤、自建卡表单填量、历史行;官方卡的数值想改的告诉 agent — owner: me · after: T5 · verify: 用户说可以
- [ ] T7 文档:`docs/default_card_templates.md`(字段说明加 amounts)— owner: agent · verify: 用户过目

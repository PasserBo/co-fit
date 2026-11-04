# 默认卡片(card_templates)扩充提案(v0 · 2026-11-04 · 待决议)

> 状态:**提案,未实施**。与 [avatar_system_design.md](avatar_system_design.md) §4 配套:每张默认卡指定一个 `motionId`。
> 决议后:① 仓库内建立模板 SSOT 并走 CI 部署;② 按下表写入 Firestore;③ 调整首启种子牌组。

---

## 1. 现状(代码事实)

- 默认卡只存在于 Firestore `card_templates`(rules:登录可读,客户端不可写),**仓库里没有任何副本、没有播种脚本**,目前靠 console 手填。本地无法读到线上到底有几张(firebase CLI 没有读文档命令),**扩充前请把线上现有模板清单贴给我**,或直接以本提案全量覆盖。
- 文档字段:`name`(string)、`type`(自由字符串,`ActionType.fromRaw` 含 strength/cardio/core/flexibility 或 力量/有氧/核心/柔韧 即可归类)、`ablyActionId`(string)、`defaultDurationSec`(int)、`intensityBaseline{label}`(可选,label 含「慢/轻」→ 慢节奏、含「快/高」→ 快节奏)。
- 首启种子牌组 `SeedDefaultDecksUsecase` 按**下标**取卡(`cards[(i*2+j) % n]`),模板一多就会组出奇怪的牌组,需要改成按 id 指定。
- 自建卡表单的强度文案是「轻松 / 中等 / 挑战」,默认卡的 `intensityBaseline.label` 建议对齐这三个词(「轻松」命中「轻」→ 慢;「挑战」不含「快/高」→ 标准,见 §3 的 tempo 列)。

## 2. 模板 SSOT 与部署方式

与 firestore.rules 同一套路:**仓库是唯一事实源,push main 由 CI 用 service account 写入**,不本地 deploy。

- 文件:`firestore/card_templates.json`(数组,每项含 `id` + 字段),与 rules 并列。
- 脚本:`tool/seed_card_templates.mjs`(firebase-admin,`set(..., {merge:false})` 全量覆盖;不在 JSON 里的线上文档 → 删除,保证线上 = 仓库)。
- 工作流:`.github/workflows/deploy-card-templates.yml`,触发条件 `paths: ['firestore/card_templates.json']`,复用 `FIREBASE_SERVICE_ACCOUNT` secret。
- 客户端不变:仍是 `FirebaseActionTemplateRepository.getTemplateCards()` 一次性拉全表(32 张 ≈ 10KB,无需分页)。
- 新增可选字段:`motionId`(string,见 avatar 提案)、`equipment`(`none|dumbbell|mat|rope`,仅展示/筛选,不进入 enum)、`order`(int,牌库排序,现状按 Firestore 默认顺序不稳定)。rules `card_templates` 本来就是只读,不用改。

## 3. 首批 32 张默认卡

时长取「打一张牌 = 一组」的尺度(30–120s),与自建卡预设 `[30,45,60,90,120]` 一致;`tempo` 是 `AvatarTempo.fromIntensityLabel` 的推断结果,仅供核对。

### 力量 strength(8)

| id | name | motionId | 默认时长 | 强度 label | tempo | equipment | 备注 |
|---|---|---|---|---|---|---|---|
| squat | 深蹲 | squat | 60 | 中等 | 标准 | none | 现有原型 |
| lunge | 弓步蹲 | lunge | 60 | 中等 | 标准 | none | 侧视,左右腿交替 |
| pushup | 俯卧撑 | pushup | 45 | 挑战 | 标准 | mat | 侧视 |
| glute_bridge | 臀桥 | glute_bridge | 60 | 轻松 | 慢 | mat | 侧视 |
| wall_sit | 靠墙静蹲 | wall_sit | 45 | 挑战 | 标准 | none | 静姿 + 微颤;自习室友好 |
| biceps_curl | 哑铃弯举 | biceps_curl | 60 | 中等 | 标准 | dumbbell | 道具:哑铃 |
| shoulder_press | 肩上推举 | shoulder_press | 60 | 中等 | 标准 | dumbbell | 道具:哑铃 |
| calf_raise | 提踵 | calf_raise | 60 | 轻松 | 慢 | none | 站立可做,自习室友好 |

### 有氧 cardio(8)

| id | name | motionId | 默认时长 | 强度 label | tempo | equipment | 备注 |
|---|---|---|---|---|---|---|---|
| jumping_jack | 开合跳 | jumping_jack | 45 | 中等 | 标准 | none | 正面 |
| run_in_place | 原地跑 | run_in_place | 60 | 中等 | 标准 | none | 现有原型 |
| high_knees | 高抬腿 | high_knees | 30 | 挑战 | 标准 | none | 侧视,膝盖抬到 90° |
| burpee | 波比跳 | burpee | 30 | 挑战 | 标准 | none | 侧视,蹲-撑-跳 三段 |
| mountain_climber | 登山跑 | mountain_climber | 30 | 挑战 | 标准 | mat | 侧视 |
| jump_rope | 跳绳 | jump_rope | 60 | 中等 | 标准 | rope | 道具:绳(可无实物) |
| skater | 滑冰步 | skater | 45 | 中等 | 标准 | none | 正面左右跳 |
| march | 原地踏步 | march | 90 | 轻松 | 慢 | none | 低强度版原地跑,久坐起身用 |

### 核心 core(8)

| id | name | motionId | 默认时长 | 强度 label | tempo | equipment | 备注 |
|---|---|---|---|---|---|---|---|
| plank | 平板支撑 | plank | 45 | 挑战 | 标准 | mat | 现有原型 |
| side_plank | 侧平板 | side_plank | 30 | 挑战 | 标准 | mat | 正面视角(身体朝观众) |
| crunch | 卷腹 | crunch | 45 | 中等 | 标准 | mat | 侧视 |
| bicycle_crunch | 空中单车 | bicycle_crunch | 45 | 中等 | 标准 | mat | 侧视,腿交替 |
| russian_twist | 俄罗斯转体 | russian_twist | 45 | 中等 | 标准 | mat | 正面,躯干左右转 |
| dead_bug | 死虫式 | dead_bug | 60 | 轻松 | 慢 | mat | 侧视,对侧手脚 |
| bird_dog | 鸟狗式 | bird_dog | 60 | 轻松 | 慢 | mat | 侧视 |
| leg_raise | 仰卧举腿 | leg_raise | 45 | 中等 | 标准 | mat | 侧视 |

### 柔韧 flexibility(8)

| id | name | motionId | 默认时长 | 强度 label | tempo | equipment | 备注 |
|---|---|---|---|---|---|---|---|
| neck_stretch | 肩颈拉伸 | neck_stretch | 60 | 轻松 | 慢 | none | 现有原型;自习室友好 |
| cat_cow | 猫牛式 | cat_cow | 60 | 轻松 | 慢 | mat | 侧视,脊柱起伏 |
| downward_dog | 下犬式 | downward_dog | 45 | 轻松 | 慢 | mat | 侧视静姿 + 呼吸起伏 |
| child_pose | 婴儿式 | child_pose | 60 | 轻松 | 慢 | mat | 侧视静姿 |
| forward_fold | 站立前屈 | forward_fold | 45 | 轻松 | 慢 | none | 侧视 |
| hip_stretch | 髋部拉伸 | hip_stretch | 60 | 轻松 | 慢 | mat | 正面(鸽子式简化) |
| side_bend | 站立体侧屈 | side_bend | 45 | 轻松 | 慢 | none | 正面,自习室友好 |
| breathing | 深呼吸放松 | breathing | 90 | 轻松 | 慢 | none | 正面,胸腔缩放;「休息也算打卡」 |

`type` 字段统一写英文枚举名(`strength/cardio/core/flexibility`),`ablyActionId` = `id`(事件标识与文档 id 一致,方便日志排查)。

## 4. 首启种子牌组改为按 id 指定

| 牌组 | 卡(按顺序) | 设计意图 |
|---|---|---|
| 考研自习室 | neck_stretch, side_bend, calf_raise, wall_sit, breathing | 不离开座位旁、不出声、不出汗 |
| 晨间唤醒 | cat_cow, jumping_jack, squat, forward_fold | 5 分钟内从床到清醒 |
| 碎片时间 | squat, plank, march | 随时能打的三张 |

`SeedDefaultDecksUsecase` 改为固定 id 列表,线上缺卡时跳过该 id(不崩)。

## 5. 待决议

1. 以上 32 张是否全量覆盖线上现有模板?还是先贴线上清单给我合并。
2. 是否接受新增 `motionId / equipment / order` 三个可选字段(rules 不用改)。
3. 「自习室友好」标签是否值得做成 `tags` 字段供牌库筛选(本期不建议,先用牌组表达)。
4. 名称是否需要英文/日文副本(`nameEn` 等)——现在 App 无多语言,建议不加。

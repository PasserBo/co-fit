# 运动小人系统设计提案(v0.1 · 2026-11-04 · 待决议)

> 状态:**提案,未实施**。目的是把「形象自定义(收费点)」与「大量不同的运动表现(UX)」两条需求放进一个可演进的架构里,
> 并列出需要用户/设计拍板的决议点。决议后按 §8 的阶段落地,并把结论回写到 [README.md](README.md) 与 [ui_overhaul/STATUS.md](ui_overhaul/STATUS.md)。
>
> v0.1:按 [avatar_game_references.md](avatar_game_references.md)(换装/养成游戏的做法)修订 —— 槽位加花纹与道具换色、软货币「汗滴」、月度限定、小人等级与连胜、明确不做 gacha/硬货币/退化惩罚。
> 三层结构已认可(2026-11-04);逐阶段的接口/文件/rules/测试见 [avatar_implementation_plan.md](avatar_implementation_plan.md)。
> **形象与骨骼本身也在重设计范围内**:§3.1 的 #14a 几何与 8 根骨骼只是现状描述,定稿以 [avatar_character_design.md](avatar_character_design.md)(三方向 + 14 根骨骼树 + 挂点)与可动探索页 [avatar_design_exploration.html](avatar_design_exploration.html) 为准。

---

## 0. 现状与约束

**现状(代码事实)**

| 层 | 现在 | 文件 |
|---|---|---|
| 动画指令 | `AvatarMotion{state, actionType, tempo}`,运动 loop **只按 4 个卡牌类型走通用原型** | `avatar/domain/entity/avatar_motion.dart` |
| 编排 | `AvatarMotionSequencer`:idle → windup ×1 → exercise loop ⇄ paused → finish ×1 → idle | `avatar/presentation/motion/avatar_motion_sequencer.dart` |
| 渲染 | `VectorAvatarRenderer`:CustomPaint 手写几何,**每个动作一段 paint 代码**,4 个 loop + 4 个状态 | `avatar/presentation/renderer/vector_avatar_renderer.dart` |
| 接口 | `AvatarRenderer.build(motion, appearance, height, phaseSeed, onOneShotComplete)`;`AvatarAppearance{body, aura, auraOpacity, headRing}` 只是 4 个颜色 | `avatar/presentation/renderer/avatar_renderer.dart` |
| 形象数据 | `users/{uid}.avatarConfig` 是 `{presetId:'default'}` 占位 map;rules 只校验 `is map` | `profile/domain/entity/user_profile_entity.dart`、`firestore.rules` |
| 房间同步 | Ably presence data = `{nickname, activity{activityState, actionKey, templateId, templateName, …}}`;**`actionKey` = 卡片 `rawType`(类型字符串)**,远端只能知道「类型」不知道具体动作 | `room/domain/entity/room_presence_member.dart`、`user_activity_status_entity.dart` |
| 卡片 | `ActionTemplateCard{id, name, type, rawType, ablyActionId, defaultDurationSec, intensityBaseline}`;`ablyActionId` 目前只随事件发出,未参与动画 | `action/domain/entity/action_template_card.dart` |
| 配色规则 | **自己 = 白身 + lime 头环;好友 = 整个小人 = 状态色**(#6b 定稿) | `room/presentation/widget/avatar_bubble.dart` |

**约束**

- iOS-only、Flutter;同屏可能 10+ 个小人,每个 46px(好友)/ 60px(自己)/ 78px(hero)。
- 必须遵守 README「关键帧同步规范」:单一时钟、镜像取反、相位由结构保证。
- 设计 token 铁律:组件只引用语义 token。
- 付费只能走 Apple IAP(审核 3.1.1);不得再出现「即将上线」占位(2.1,已被拒过一次)。
- Ably presence 是整包替换;Firestore 第一帧可能来自缓存。

**这次要推翻的旧决议**:README §小人动作动画写的「动画只按 4 个卡牌类型走通用原型,不细分具体动作」。本提案把它改成「**每张卡可指定具体动作(motion),类型原型只做兜底**」。

---

## 1. 目标拆解

把「小人系统」拆成三个正交子系统,各自独立演进:

```
┌─────────────── 形象 Appearance ───────────────┐   谁在动:身体/颜色/配饰/光效 —— 用户可自定义,收费点
│  AvatarConfig(槽位 × 物品 id)+ 目录 + 权益   │
└───────────────────────┬───────────────────────┘
                        │ 配饰挂在骨骼上,自动跟随任何动作
┌───────────────────────▼───────────────────────┐
│ 渲染 Renderer:骨架 Rig + 部件 Part 绘制       │   怎么画:单一时钟采样 clip → 骨骼变换 → 画部件
└───────────────────────▲───────────────────────┘
                        │ 任何动作对任何形象都成立
┌─────────────── 动作 Motion ───────────────────┐   在做什么:每张卡一个 motionId → MotionClip(关键帧数据)
│  MotionClip 库(数据,不是代码)+ 类型原型兜底 │
└───────────────────────────────────────────────┘
```

核心思想:**形象 × 动作 的组合不能靠「每种组合画一遍」实现**,必须让「形象」挂在「骨骼」上、「动作」只驱动「骨骼」。这样 N 件配饰 × M 个动作的成本是 N + M,而不是 N × M。

---

## 2. 渲染技术选型

| 方案 | 形象自定义 | 动作扩展成本 | 帧同步规范契合 | 同屏 10+ 性能 | 依赖/包体 | 设计师可产出 | 结论 |
|---|---|---|---|---|---|---|---|
| **A. 现状:手写 CustomPaint** | ✗ 每个动作里硬编码部件 | 每个动作 50–80 行 paint 代码,配饰要在每个动作里重画 | ✓ | ✓ | 无 | ✗ | 不可扩展 |
| **B. 自研「骨架 + 关键帧数据」矢量渲染(推荐)** | ✓ 部件/配饰挂骨骼,自动跟随 | 一个动作 = 一份声明式 clip 数据(~20 行),无新 paint 代码 | ✓ 天然满足(一个 controller 采样全部轨道) | ✓ 仍是 CustomPaint | 无 | △ 需要 widgetbook 工作台;设计师给 #14a 式关键帧表,工程转 clip | **P1 落地** |
| **C. Rive** | △ 需 data binding / nested artboard,每件配饰要在编辑器里绑骨;与 Flutter 主题 token 脱节 | ✓ 设计师直接做 | △ 自带时钟,需用 `RiveAnimationController` 手动驱动才能保证相位 | △ 每个实例一个 artboard,10+ 个要测 | +rive 包(~几 MB)+ `.riv` 资产 | ✓ | 作为 **P5 高级皮肤**可选,走同一 `AvatarRenderer` 接口 |
| D. Lottie | ✗ 不能运行时换件 | ✓ | ✗ | △ | +lottie | ✓ | 否 |
| E. 精灵图 / sprite sheet | ✗ 组合爆炸(形象 × 动作 × 帧) | △ | ✓ | ✓ | 资产巨大 | ✓ | 否 |
| F. 3D(Flutter GPU / 第三方) | ✓ | ✓ | ✓ | ✗ 风险高 | 大 | ✓ | 否,与品牌几何风不符 |

**推荐 B 的理由**

1. 品牌已经是「几何小人」(App 图标、启动图、登录页都是它),矢量几何本身就是视觉资产,不需要换引擎来换风格。
2. 现有 4 个原型动作已经事实上是「骨骼变换」(rotate/scale/translate around pivot),只是写成了代码;改成数据是重构不是重写。
3. 帧同步规范(单一时钟 + 镜像取反)在 B 里是**结构保证**:采样函数 `pose(t)` 是纯函数,没有第二个时钟可漂。
4. 不引入新依赖、不增加包体,不产生 Rive 编辑器的学习与资产成本;将来真要 Rive,只是再写一个 `AvatarRenderer` 实现(接口已经为此预留)。
5. 收费物品是「数据 + 一段 Path」,可以在 App 内用 widgetbook 一天做出十几件,迭代比 Rive 快得多。

**B 的代价与对策**

- 手写关键帧数据费眼 → 做一个 widgetbook「动作工作台」(knob 调时间轴、选形象、选 clip、对比 2 个小人相位),hot reload 即预览。
- 46px 下动作难辨认 → 每个 clip 要过「剪影测试」(§4.4);配合道具(哑铃/垫子/跳绳)与动作 chip 文字。
- 矢量风格上限 → 高级皮肤走 P5 Rive 渲染器,或在矢量里加粒子/拖尾等光效物品(aura slot)。

---

## 3. 渲染层设计:Rig + Clip + Part

### 3.1 骨架 Rig

保留 #14a 的 80×100 视框与「四肢与躯干分离悬浮」的风格。两套视角(现状已隐含):

```
RigView.front(正面):  head, torso, armL, armR, legL, legR
RigView.side (侧面):  head, torso, armNear, armFar, legNear, legFar
```

每根骨骼 = `(pivot, restRect)`;骨骼变换 = `(dx, dy, rotDeg, scaleX, scaleY)`,与现在 `_rotateAround / _scaleYAround` 一致。
`root` 骨骼承载整体位移/倾斜(hop、前倾 8°、暂停摇摆)。

### 3.2 动作 Clip(数据)

```dart
/// 一个动作 = 哪套骨架 + 周期 + 每根骨骼的关键帧轨道 + 镜像规则 + 道具。
class MotionClip {
  final String id;              // 'squat' / 'jumping_jack' / 'plank' …
  final RigView rig;
  final Duration period;        // 走 token:CoFitMotion.avatarLoop* 扩成按 clip 的表
  final Map<Bone, Track> tracks;// Track = 有序关键帧 [(t, BoneTransform)] + 缓动
  final Map<Bone, Mirror> mirrors; // armR = negate(armL) 这类规则,保证相位
  final List<Prop> props;       // dumbbell / mat / rope / kettlebell …(挂在某骨骼上)
  final double auraRx;          // 光圈宽(核心类动作加宽到 24)
  final HoldSpec? hold;         // 柔韧类「顶点停留 20%」
}
```

- 采样:`Pose pose(MotionClip clip, double t)`,纯函数;`t = (controller.value + phaseSeed) % 1`。
- 2 倍频子运动(hop)用 `(t * 2) % 1` 的频率映射写在 clip 里,不另开时钟(规范 6)。
- 现有 4 个原型 + idle/windup/paused/finish **全部重新表达为 clip**,渲染结果与现在像素一致 —— 这是 P1 的验收标准。
- clip 以 **Dart const 数据**放在 `avatar/data/motion_clips/*.dart`,不走 JSON:它与骨架定义强耦合,没有「不发版热更」的需求;const 给类型检查。

### 3.3 部件 Part 与配饰

模型照搬 Spine 的「slot / attachment / skin」:`AvatarConfig` 就是一张「槽位 → 附件 id」的表,动画完全不知道表里填了什么。
槽位按 z 序从后到前(参考 Fall Guys「形态 × 颜色 × 花纹」三分法,三者各自独立、组合相乘而成本相加):

```
aura        光圈/地面光效(粒子、拖尾、双环)——程序动画,可售
pet         跟随宠物(独立小动画,P4+ 再做)
body        躯干形态:capsule(默认)/ round / tall
pattern     花纹:none / stripe / dots / gradient …(一个 clip path,适配所有形态)
bodyColor   身体色:色板命名色
limbBand    四肢色环(护腕/护膝/袜子,运动装备化)
face        表情(默认 none,保持极简)
eyewear     运动眼镜等
headwear    发带 / 帽子 / 猫耳
handheld    待机手持(水壶、毛巾),仅 idle/paused
propSkin    道具换色(金色哑铃、荧光跳绳)——道具属于 clip,这里只换它的颜色
celebration finish 阶段的庆祝特效(烟花 / 双跳 / 比心)——程序动画,可售
```

- 每件物品 = `AvatarItem{id, slot, anchor: Bone, painter: PartPainter, rarity, unlock}`。
- `PartPainter` 在骨骼局部坐标里画(`canvas` 已被骨骼变换过),所以**任何物品自动跟随任何 clip**(Among Us 早期每顶帽子要为每帧手标偏移,就是没有这一层)。
- 侧视 rig 下部分槽位要给第二份 path(如帽子的侧视轮廓);没给就按正面画(先这样,够用)。
- 颜色只允许来自 token 色板(`CoFitPalette`)的命名色,物品数据里存色名不存 hex。
- 槽位总数控制在 12 个以内;每个槽位的差异必须在 46px 可见,物品同样要过 §4.4 的剪影测试。`celebration` / `aura` / `pattern` / `propSkin` 是**零原画成本**的内容倍增器,优先做。

### 3.4 性能

- 每个小人一个 `CustomPaint` + `RepaintBoundary`,`repaint: controller`,不走 setState(现状已如此)。
- 物品 Path 预构建并缓存(`Path` 是 const 不了的,用 lazy static)。
- 10 个小人 × 60fps × 十几个 drawRRect/drawPath,远低于预算;真要省电,好友小人可在 App 后台/非当前房间页降到 30fps(`Ticker.muted`)。

---

## 4. 动作子系统:从「4 类原型」到「每卡一动作」

### 4.1 数据流

```
card.motionId ──(打牌)──▶ presence.activity.motionId ──▶ 远端 AvatarBubble
                                 │ 兼容:老客户端只发 actionKey(=rawType)
                                 ▼
                 motionId 命中 clip 库?  ──否──▶ ActionType.fromRaw(actionKey) 的类型原型
```

- `ActionTemplateCard` 新增可空 `motionId`;Firestore `card_templates` / `users/{uid}/cards` 新增同名字段。现有 `ablyActionId` 保留(事件用),**不要**复用它当 motionId:它的语义是「事件动作标识」,历史数据里值混乱(`squat` / 类型名 / 任意)。
- `UserActivityStatusEntity` 新增可空 `motionId`,`actionKey` 原样保留做兜底与旧版兼容。
- `AvatarMotion` 新增可空 `motionId`;`AvatarMotionSequencer` 透传;`VectorAvatarRenderer` 查 clip 库,未命中走类型原型。老客户端看新动作 → 退回类型原型,不会出错。

### 4.2 自建卡

创建/编辑表单(`custom_card_form_sheet_view.dart`)增加「动作」选择:按类型分组的 clip 列表 + 实时预览小人;默认 = 该类型原型。这是用户第一次「看见」动作库,也是后续「付费动作包」的入口位置。

### 4.3 起手/完成

维持全局一套(0.4s / 1.1s),不按动作分;若将来做「庆祝特效」物品,挂 finish 阶段的 `trail` 槽位。

### 4.4 剪影测试(每个 clip 的验收门槛)

在 widgetbook 里以 **46px 高、纯白剪影、无 chip 文字**渲染,与同类型其它 clip 并排,3 个人里 2 个能说出是什么动作才算过。过不了就加道具或放大动作幅度,不要靠颜色。

### 4.5 首批 clip(与 [default_card_templates.md](default_card_templates.md) 对应)

| 类型 | clip(rig) |
|---|---|
| 力量 | squat(front)、lunge(side)、pushup(side)、glute_bridge(side)、wall_sit(side)、biceps_curl(front,道具哑铃)、shoulder_press(front,哑铃)、calf_raise(front) |
| 有氧 | jumping_jack(front)、run_in_place(side)、high_knees(side)、burpee(side)、mountain_climber(side)、jump_rope(front,道具绳)、skater(front)、march(side) |
| 核心 | plank(side)、side_plank(front)、crunch(side)、bicycle_crunch(side)、russian_twist(front)、dead_bug(side)、bird_dog(side)、leg_raise(side) |
| 柔韧 | neck_stretch(front)、cat_cow(side)、downward_dog(side)、child_pose(side)、forward_fold(side)、hip_stretch(front)、side_bend(front)、breathing(front) |

共 32 个;其中 4 个就是现有原型(squat / run_in_place / plank / neck_stretch),先重构再扩。

---

## 5. 形象子系统:AvatarConfig、目录、权益

### 5.1 `AvatarConfig`(替换占位 map)

```dart
@freezed class AvatarConfig {
  int v;                       // schema 版本,现 1
  String body;                 // 'capsule'(默认)/ 'round' / 'tall'
  String bodyColor;            // 色板命名色:'gray50'(默认)/ 'lime' / 'coral' …
  String? pattern;             // null = 纯色
  String? limbBand;
  String? face;                // null = 无表情(默认,保持品牌极简)
  String? headwear;
  String? eyewear;
  String? handheld;
  String? propSkin;
  String? aura;                // null = 默认光圈
  String? celebration;         // finish 阶段特效
}
```

(`head` 头型并入 `body` 形态,46px 下单独换头型看不出来。)

- 存 `users/{uid}.avatarConfig`(字段已存在,rules 已允许 map);rules 收紧为:`v is int`、各槽位 `is string`、`keys().hasOnly([...])`。
- **前向兼容**:未知物品 id → 该槽位回默认(老客户端看新物品不崩);未知 `v` → 全部默认。
- 旧数据 `{presetId:'default'}` → 读取时映射为全默认。

### 5.2 房间同步

形象要被同房间的人看到,两条路:

| 路 | 做法 | 优缺点 |
|---|---|---|
| **a. 塞进 presence data(推荐)** | `data = {nickname, avatar: config.toMap(), activity}`;改形象后 `reassertPresence()` 广播到所有房间(已有机制) | 零额外读取、实时、自描述;payload 多 ~150B,远低于 Ably 64KB 上限 |
| b. 远端按 uid 读 `users/{uid}` | rules 已允许登录用户读 | 每个成员一个 snapshot 流,缓存第一帧问题再来一次 |

选 a。`RoomPresenceMember` 加 `AvatarConfig? avatar`,缺省 = 默认形象(老客户端)。

### 5.3 目录 `AvatarCatalog`

- 目录**随 App 发版**(物品 = 代码里的 painter,不可能远程新增),Dart const 列表;每件:`id, slot, nameZh, rarity, unlock, previewAnchor`。
- `unlock` 三种:`free` / `achievement(条件)` / `pack(packId)`。
- Remote Config 只管「上架/下架/推荐位」(`avatar_pack_<id>_enabled`),走现有 `FeatureFlags` 模式。
- 审核红线:目录里**只放已经能买到或已经能解锁的东西**,不做「敬请期待」卡位。

### 5.4 免费层:软货币、成就、月度限定(留存,不是收费)

参考 Zwift(骑行产 Drops 买装备)、Pikmin Bloom(月度限定)、Finch(可赚可买双通道):

- **软货币「汗滴」**(名字待定):**唯一来源是完成卡片打卡**(按时长折算,如 1 分钟 = 1 滴),用于购买免费层物品。**不可用钱买、不可转让**,这样「某些东西只能靠练」的叙事才成立。余额 = Σ sessions 折算 − 已花费;已花费记在 `users/{uid}/entitlements/{itemId}` 的 `{source:'sweat', cost}` 里,客户端现算,不新开余额字段(防重放要等 Functions)。
- 新用户:默认形象 + 3 种身体色 + 1 条发带,免费且 onboarding 就能换(把「你的小人已就位」变成真的)。
- **成就**:连续打卡 3/7/30 天、某类型完成 50 次、与 5 个不同的人同房运动 → 各解锁一件;**成就物品不进商店、不可购买**,是炫耀资本(Zwift 的珠峰挑战车)。数据来自 `users/{uid}/sessions`,客户端现算(与运动历史页同源),**不写新集合**。
- **月度限定**:每月一件,当月打卡满 N 次自动获得,过期不补。目录随发版带未来 2–3 个月的物品,`unlock: monthly('2026-12', 12)`,Remote Config 控上架。
- 物品**不影响任何数值**(反 Habitica):穿什么都不会让运动「更有效」。

### 5.5 付费:IAP 与权益

- 商品形态:**非消耗型「形象包」直售**(一个 packId 含 4–6 件、含 1 件包限定,¥18–¥30 档;单件 ¥6)。参考 Pokémon GO 的直售 + Fall Guys 的捆绑包。
- **明确不做**:硬货币(消耗型 IAP 带来余额/退款/未消费权益的整套合规负担)、gacha(Apple 要求公示概率,且与健身调性冲突)、赛季通行证(需要赛季运营节奏,团队没有)。
- **预留订阅位置**(Finch Plus / Duolingo 模式):将来若做「CoFit+」(更多统计、Live Activities、房间上限),把「每月一件订阅专属物品」捆进去;目录的 `unlock` 枚举现在就留 `subscription` 值。
- **商店周推荐位**走 Remote Config(`avatar_store_featured` = packId 列表),目录不变只变展示,对冲「所有东西一直在卖」的平淡。
- 技术:`in_app_purchase` 插件(StoreKit 2 路径),`productId = com.passerbo.cofitapp.pack_<id>`。
- 权益存储:`users/{uid}/entitlements/{packId}` = `{source:'appstore', transactionId, originalTransactionId, purchasedAt}`;rules:仅本人 create,不可 update/delete(账号删除时与其它子集合一起由删除 usecase 清)。
- 验证:
  - **阶段一(先上)**:客户端用 StoreKit 2 的 JWS 签名 transaction(插件给 `verificationData`)本地校验后写权益。形象是纯装饰,作弊收益极低,不值得一开始就上服务端。
  - **阶段二**:Cloud Functions 用 App Store Server API 验证 + 处理退款通知(需要 Blaze 计划,当前项目没有 functions 目录)。
- 必做:「恢复购买」按钮(审核必查)、购买中态、失败 toast、权益与目录的离线缓存。
- 装备校验:**穿戴时不校验权益,渲染时也不校验**(远端渲染别人的形象时根本没有对方的权益);只在「形象编辑器」里把未拥有物品标记为锁定。这也意味着作弊者可以改 Firestore 穿上未买的物品 —— 接受。

### 5.6 状态色冲突(必须决议)

现行 #6b:**好友整个小人 = 状态色**(lime 运动 / amber 暂停 / gray 挂机)。一旦身体颜色可自定义,状态就没地方放了。提案:

| 元素 | 现在 | 提案 |
|---|---|---|
| 身体 | 好友 = 状态色;自己 = 白 | **= `bodyColor`(用户选)**,自己好友一致 |
| 头环 | 自己 lime 常亮;好友无 | **好友 = 状态色环**(运动 lime / 暂停 amber / 挂机无环);自己 = lime 常亮(身份标记) |
| 光圈 | 运动 = 类型色、暂停 = amber、挂机 = 主体 hue 18% | 不变 |
| 挂机好友 | 灰身 | 整体 `avatarInactive` 透明度(已有 token),身体色保留 |
| 动作 chip | 文字 = 状态色 | 不变 |

这样状态信息从「身体色」搬到「头环 + 光圈 + 透明度」,身体色让给用户(Among Us 的「颜色 = 身份、装饰叠在上面」已证明不损可读性)。需要设计确认(#6b 要出 6c 修订)。

### 5.7 养成:小人本身要「长」

参考 Finch(鸟随自理成长)、Zwift(等级解锁)、Duolingo(连胜):

- **小人等级**:由累计运动分钟数现算(阈值表进目录,如 Lv1 0 / Lv2 60 / Lv3 300 / Lv4 1000 / Lv5 3000 分钟)。等级只做三件事:① 解锁部分免费物品;② **头环从 1 环到 2 环到 3 环**(视觉成长,房间里所有人可见);③ 我的页展示。不做属性、不做数值。
- **连胜可视化**:连续 7 天以上,光圈带常亮微粒;断了就没。不卖「连胜冻结」(在健身 App 里卖「假装你练了」不合适)。
- **不做退化/惩罚**(旅行青蛙式离家、Tamagotchi 式变丑):久坐本身已经够内疚,App 不再踩一脚。挂机好友用透明度表达即可(`avatarInactive` 已有)。

### 5.8 社交展示

换装的全部价值在房间里兑现(Among Us 大厅、Fall Guys 庆祝动作):

- presence 必带形象(§5.2 选 a)。
- **庆祝特效**全房间可见,是最值得先做的付费物品之一;STATUS.md 里「能量爆发粒子」这个未做润色并入 `celebration` 槽位。
- 新物品上身后,房间内播一次 windup burst + chip「换了新装」,给炫耀一个瞬间。
- 我的页 hero(78px)与邀请卡小人改用真实形象:邀请卡读邀请人的 `users/{uid}.avatarConfig`(rules 已允许登录用户读),替换现在的静态剪影。

---

## 6. 数据模型变更汇总

| 对象 | 变更 | 兼容 |
|---|---|---|
| `ActionTemplateCard` | + `String? motionId` | 缺省 null → 类型原型 |
| Firestore `card_templates/*`、`users/*/cards/*` | + `motionId` | rules 允许可选 string |
| `UserActivityStatusEntity` / presence `activity` | + `motionId` | 老客户端无此键 → 兜底 |
| presence `data` | + `avatar` map | 缺省 = 默认形象 |
| `RoomPresenceMember` | + `AvatarConfig? avatar` | |
| `UserProfileEntity.avatarConfig` | `Map` → `AvatarConfig`(freezed) | 旧 `{presetId}` 映射默认 |
| `firestore.rules users/{uid}` | avatarConfig 形状校验收紧 | 走 CI 部署,diff 先给用户 |
| 新集合 `users/{uid}/entitlements` | 仅本人 create | 账号删除 usecase 要加清理 |
| `AvatarMotion` | + `String? motionId` | |
| `AvatarAppearance` | 颜色 4 元组 → `AvatarConfig` + 状态派生色(`ringColor, auraColor, auraOpacity, inactive`) | 渲染实现仍不读主题 |
| token | `CoFitMotion.avatarLoop*` 4 个 → 按 clip 的周期表;新增物品用到的色名 | 进 `cofit.tokens.json` 再同步 |

目录结构(按架构规则):

```
lib/features/avatar/
  domain/entity/   avatar_config.dart, avatar_item.dart, motion_clip.dart, avatar_motion.dart
  domain/          avatar_catalog_repository.dart, entitlement_repository.dart
  data/            avatar_catalog.dart(const 目录), motion_clips/*.dart, firebase_entitlement_repository.dart,
                   store_kit_purchase_gateway.dart
  usecase/         update_avatar_config_usecase.dart, purchase_pack_usecase.dart, restore_purchases_usecase.dart,
                   resolve_unlocks_usecase.dart(成就)
  presentation/    renderer/(rig, pose sampler, part painters), motion/(sequencer), 
                   view/avatar_editor_page_view.dart, view/avatar_store_sheet_view.dart,
                   widget/avatar_preview.dart, widget/item_grid.dart
  provider/        …
```

---

## 7. UI 入口(需设计稿)

1. **形象编辑器**(我的页「编辑形象」按钮恢复,`MyPageBody.onEditAvatar` 已留回调):上半大号小人实时预览(可切 idle / 任一动作 / 完成特效看效果,**试穿**未拥有物品),下半槽位 tab + 物品网格(已拥有 / 汗滴价格 / 解锁条件 / 所在形象包),右上汗滴余额与等级。
2. **形象包 sheet**:包内物品一览 + 价格(来自 StoreKit 本地化价格)+ 购买 + 恢复购买;顶部周推荐位。
3. **Onboarding**:「你的小人已就位」下加 3 个免费身体色快捷选择(一屏不变)。
4. **自建卡表单**:「动作」行 + 预览。
5. **房间**:按 §5.6 修订配色。

---

## 8. 落地阶段与估算

| 阶段 | 内容 | 验收 | 估算 |
|---|---|---|---|
| **P1 引擎重构** | Rig + Clip + Pose 采样器;现有 8 个状态/动作改为数据;widgetbook 动作工作台;帧同步单测(镜像/相位纯函数测试) | 房间视觉与现在逐帧一致;`flutter test` 全绿 | 2–3 天 |
| **P2 动作扩展** | `motionId` 贯通(卡片 → presence → 渲染);32 个 clip;默认卡模板 SSOT + CI 部署(见 default_card_templates.md);自建卡动作选择 | 新老客户端混房不崩;每个 clip 过剪影测试 | 4–6 天(clip 制作占大头) |
| **P3 形象自定义(免费层)** | `AvatarConfig` 实体 + rules;presence 携带;编辑器页(含试穿);默认 + 免费物品 ~12 件(身体色/花纹/发带/光圈);汗滴 + 成就 + 等级/连胜(客户端现算);状态色迁移(#6c);onboarding 快捷色;新装 burst | 换形象后同房间的人 1s 内看到;汗滴余额与历史页数据一致 | 5–7 天 |
| **P4 付费** | IAP 接入、权益集合、形象包 sheet(周推荐位)、恢复购买、月度限定;首批 2 个付费包各 4–6 件(至少各含 1 个庆祝特效) | 沙盒购买/恢复通过;账号删除清权益 | 3–4 天 + App Store Connect 配置 |
| P5(可选) | Rive 渲染器做高级皮肤 | — | 视设计资源 |

P1 与「默认卡扩充」互不阻塞,可并行;P2 依赖 P1;P3 依赖 P1(部件挂骨骼);P4 依赖 P3。

---

## 9. 需要拍板的决议

1. **技术路线**:自研骨架 + 关键帧数据(方案 B)作为主引擎,Rive 仅作可选高级皮肤 —— 同意?
2. **推翻旧决议**:从「4 类原型」改为「每卡一 motionId,类型原型兜底」 —— 同意?
3. **状态色迁移**(§5.6):身体色让给用户,状态搬到头环 + 光圈 + 透明度 —— 需要设计出 #6c。
4. **收费形态**:非消耗型形象包先行,不做订阅/代币;阶段一客户端验证 —— 同意?
5. **免费层经济**:软货币「汗滴」(只靠打卡获得、不可购买)+ 成就物品不进商店 + 月度限定 —— 要不要全上?货币叫什么?
6. **养成**:小人等级(累计分钟 → 头环环数)+ 连胜微粒;明确不做数值、不做退化惩罚 —— 同意?
7. **首批物品范围**:身体色 × 6、花纹 × 3、形态 × 2、发带/帽子 × 4、眼镜 × 2、光圈特效 × 2、庆祝特效 × 2 作为免费层 + 首个付费包的规模是否合适?
8. 自建卡的「动作」是否对所有用户免费开放全部 32 个 clip(推荐:是;付费只卖形象与特效,不卖动作)?
9. 宠物(`pet` 槽位,跟随本体的独立小动画)是否列入 P4 之后的规划?

# 小人系统实施计划(v0 · 2026-11-04)

> 配套 [avatar_system_design.md](avatar_system_design.md)(三层结构:形象 / 渲染 / 动作,已认可)与
> [avatar_game_references.md](avatar_game_references.md)。本文把每一阶段展开到**接口、文件、rules diff、测试、验收**。
> 每阶段结束回写 [ui_overhaul/STATUS.md](ui_overhaul/STATUS.md);README §小人动作动画 在 P2 结束时重写。

阶段依赖:`P0 角色设计` → `P1 引擎` → `P2 动作贯通`(与 `默认卡 SSOT` 可并行)→ `P3 形象免费层` → `P4 付费`。

> **2026-11-04 修订**:形象本身纳入重设计范围(见 [avatar_character_design.md](avatar_character_design.md)),
> P1 不再以「与现有胶囊小人像素一致」为验收,而是按 P0 定稿的新骨骼实现引擎;下文 1.2–1.4 的几何数值以 P0 定稿为准替换。

---

## P0 角色设计(1–2 天 + 用户决议)

| 步 | 产物 | 状态 |
|---|---|---|
| 0.1 | 三方向可动探索页 [avatar_design_exploration.html](avatar_design_exploration.html)(A 胶囊 2.0 / B 豆豆 / C 线条 × 待机/开合跳/深蹲/俯卧撑 × 46–170px + 骨骼叠加 + 剪影条) | ✅ 已做 |
| 0.2 | 用户选方向 | ✅ **B 豆豆**(2026-11-04) |
| 0.3 | 角色设定稿 [avatar_bean_sheet.html](avatar_bean_sheet.html):转面/比例网格/9 挂点/面部与状态描边/换装样例/五档尺寸 + 图标示意 | ✅ 已做,待用户确认 |
| 0.4 | 骨骼规格表 [avatar_bean_spec.md](avatar_bean_spec.md) §1–4:14 根骨骼的枢轴 / rest 几何 / 自由度上限、9 个挂点、侧视规则 | ✅ 已做,待用户确认 |
| 0.5 | 8 个基础状态关键帧表 [avatar_bean_spec.md](avatar_bean_spec.md) §5,可动版在设定稿页第 6 节 | ✅ 已做,待用户确认 |
| 0.6 | 引擎路线 | ✅ **纯 Dart**(2026-11-04) |

---

## P1 引擎重构:Rig + Clip + Pose(3–4 天)— ✅ 完成 2026-11-04

> 落地位置:`lib/features/avatar/presentation/renderer/{rig/,clips/,motion_clip_library.dart,rig_avatar_painter.dart}`;测试 `test/features/avatar/presentation/renderer/`(rig / sampler / golden 8 张);widgetbook「动作工作台」。与计划的偏差:类型放 presentation/renderer 而非 domain/entity(渲染层概念),不用 freezed;IK(`Track.ik`)未做,平板用 basePose 直接摆姿势,留到 P2 需要手贴地的动作时再加。

### 1.1 不变量(验收标准)

1. P0.5 的 8 个基础状态在 widgetbook 工作台里与关键帧表一致(人工对照 + golden 固化,golden 由新实现生成,不再以旧渲染器为基线)。
2. README 帧同步规范 6 条全部由结构保证:一个 `AnimationController`、`pose(t)` 纯函数、镜像取反、相位偏移 `(value + seed) % 1`。
3. 对外接口 `AvatarRenderer.build(...)` 签名不变;`room/` 与 `IdleAvatarFigure` 零改动(旧 `VectorAvatarRenderer` 的 8 状态由新 clip 替换,视觉随新形象改变)。
4. 骨骼树为 P0 定稿的 14 根(root / pelvis / spine / head / 上臂·前臂 ×2 / 大腿·小腿 ×2),四肢段只转不缩;`Track.ik(target)` 解析式双骨 IK 可用。

### 1.2 核心类型(`lib/features/avatar/domain/entity/`)

```dart
/// 骨骼(P0 定稿的 14 根;front/side 共用同一棵树,side 时 L/R 解释为 near/far)。
enum Bone {
  root,            // 整体位移/旋转/挤压拉伸
  pelvis,          // 骨盆:位移(深蹲下沉)
  spine, head,     // 脊柱(躯干/蛋体):旋转 + scaleY;头:旋转
  uarmL, farmL, uarmR, farmR,      // 上臂 → 前臂(枢轴 肩/肘)
  thighL, shinL, thighR, shinR,    // 大腿 → 小腿含脚(枢轴 髋/膝)
}

enum Facing { front, side }        // side 的左右翻转 = root.scaleX −1
enum Socket { crown, face, chest, handL, handR, footL, footR, back, ground }

/// 单骨骼变换,全部相对 rest pose,pivot 由 rig 提供。
@freezed class BoneTransform {
  @Default(0) double dx, dy, rotDeg;
  @Default(1) double scaleX, scaleY;
  @Default(1) double opacity;
}

/// 骨骼定义:父骨骼、pivot、rest 矩形(#14a 80×100 视框坐标)。
class BoneDef { final Bone? parent; final Offset pivot; final Rect rest; final double radius; }

class Rig {
  final RigView view;
  final Map<Bone, BoneDef> bones;      // 绘制顺序 = map 插入顺序(远侧先画)
  static const front = Rig(...);       // torso(32.5,38,15,24) head(40,26,r8) arm(24.5/50,41,5.5,12) leg(33/41.5,66,5.5,12)
  static const side  = Rig(...);       // 跑步长臂 (37.25,46,5.5,18) pivot 肩(40,44);腿 pivot 髋(40,67)
}

/// 轨道:关键帧(首选)或采样函数(逃生口,用于 sin/easeOutBack 这类非分段缓动)。
sealed class Track {
  const factory Track.keys(List<Key> keys) = KeyTrack;       // Key(t, BoneTransform, Curve curveToNext)
  const factory Track.sampled(BoneTransform Function(double t) fn) = SampledTrack;
}

/// 镜像规则:目标骨骼 = 源骨骼的某些分量取反(rotDeg / dx),保证相位。
class Mirror { final Bone source; final bool negateRot, negateDx; }

/// 特效(与骨骼无关的程序绘制):光圈宽度、burst 环。
sealed class ClipEffect {
  const factory ClipEffect.aura({double rx}) = AuraEffect;
  const factory ClipEffect.burst({required double start, required double speed}) = BurstEffect;
}

class MotionClip {
  final String id;
  final RigView rig;
  final Duration period;                  // 见 1.5 token 决议
  final bool loop;                        // false = ×1(windup/finish)
  final Map<Bone, BoneTransform> basePose;// 静态姿势(核心支撑这类「先摆好再微颤」)
  final Map<Bone, Track> tracks;
  final List<Mirror> mirrors;
  final List<ClipEffect> effects;
  final List<Prop> props;                 // P2 引入
}

/// 采样结果:每根骨骼一个世界变换矩阵 + 全局 opacity,纯值对象。
class Pose { final Map<Bone, Matrix4> world; final double opacity; final List<ClipEffect> effects; }
```

`lib/features/avatar/presentation/renderer/`:

```dart
/// 纯函数:clip × t → Pose。先 basePose,叠加 tracks,再按 mirrors 派生,最后沿 parent 链合成世界矩阵。
class PoseSampler { static Pose sample(MotionClip clip, Rig rig, double t); }

/// 把 Pose 画出来:按 rig 绘制顺序,对每根骨骼 canvas.transform(world[bone]) 后调用部件绘制。
/// P1 的部件绘制 = 现在的 _drawRRect / _drawHead(白身 + 头环);P3 替换为 PartPainter 链。
class RigAvatarPainter extends CustomPainter { ... }   // repaint: controller,与现在一致

/// clip 查找:motionId → clip;未命中 → 类型原型;再未命中 → strength 原型。
class MotionClipLibrary { MotionClip resolve({String? motionId, ActionType? type, required AvatarMotionState state}); }
```

`VectorAvatarRenderer`/`VectorAvatarFigure` 保留名字与 controller 生命周期,只把 `_AvatarPainter` 换成 `RigAvatarPainter`。

### 1.3 现有 8 状态 → clip 翻译表

| clip | rig | period | 轨道(全部从同一 t 派生) | 效果 |
|---|---|---|---|---|
| `idle` | front | bobPeriod 2.4s | root.dy keys (0,0)(.5,−5)(1,0) easeInOut | aura rx17 |
| `windup` ×1 | front | 0.4s | root.scale sampled `1+0.16·sin(π·easeOut(t))` pivot(40,60);臂 = side 姿(basePose) | burst(start 0) |
| `squat`(力量原型) | front | 1.3s | legL/legR.scaleY keys (0,1)(.5,.58)(1,1) pivot 脚底(40,78);upper.dy keys (0,0)(.5,10)(1,0);armL.rot keys (0,−10)(.5,−75)(1,−10) pivot(27.25,42);armR = mirror(armL, negateRot) | aura rx17 |
| `run_in_place`(有氧原型) | side | 0.6s | root.dy keys (0,0)(.25,−2.5)(.5,0)(.75,−2.5)(1,0)(2 倍频 hop);root.rot 常量 8° pivot(40,84);legNear.rot keys (0,−32)(.5,32)(1,−32) pivot(40,67);legFar = mirror(legNear);armNear.rot keys (0,35)(.5,−35)(1,35) pivot(40,44);armFar = mirror(armNear);head.dx 常量 +2 | aura rx17 |
| `plank`(核心原型) | side | 0.9s | basePose:torso rot −6° rect(24,60,30,13)、armNear rot 35° rect(19.25,72,5.5,12)、legNear rect(49,73,5.5,11)、head(62,54);root.dy keys (0,0)(.5,1.6)(1,0) | aura rx24 |
| `neck_stretch`(柔韧原型) | front | 2.6s | upper.rot keys (0,0)(.4,−16)(.6,−16)(1,0) pivot(40,64);armR.rot 常量 −150° pivot(52.75,42);armL 垂放 | aura rx17 |
| `paused` | front | 3.0s | root.rot keys (0,−5)(.5,5)(1,−5) pivot(40,84);opacity .75 | aura rx17 |
| `finish` ×1 | front | 1.1s | root.dy sampled(主跳 −16 + 二段 −6);armL.rot sampled `150·easeOutBack(clamp(t/.35))`,armR mirror | burst(0, 1.6) + burst(.12, 1.6) |

侧视 rig 的远侧肢体 = body @80%(`CoFitOpacities.farLimb`)由 `RigAvatarPainter` 按骨骼名(`*Far`)派生,不进 clip。

### 1.4 文件与提交顺序

| # | 提交 | 内容 | 测试 |
|---|---|---|---|
| 1 | `feat(avatar): Rig 常量 + 挂点` | 按 P0.4 骨骼规格表写 `Rig.front / Rig.side`(枢轴、rest 矩形、父子关系、挂点);`rig_test.dart` 校验每根骨骼的父存在、枢轴在父的 rest 范围内 | 单测 |
| 2 | `feat(avatar): Rig/Clip/Pose 类型 + PoseSampler` | 新文件:`domain/entity/{bone.dart, bone_transform.dart, motion_clip.dart, track.dart}`、`presentation/renderer/{rig.dart, pose_sampler.dart}` | `pose_sampler_test.dart`:① mirror 对称 ∀t;② `sample(0) == sample(1)`;③ `(t+seed)%1` 与 controller 起点无关;④ hold 段取值恒 1;⑤ 父子矩阵合成(upper 动则 head 跟) |
| 3 | `feat(avatar): 8 基础状态 clip + 新 painter` | `data/motion_clips/{core_states.dart(idle/windup/paused/finish), prototypes.dart(4 原型)}`(按 P0.5 关键帧表)、`presentation/renderer/{motion_clip_library.dart, rig_avatar_painter.dart}`;`vector_avatar_renderer.dart` 换 painter;删旧 `_AvatarPainter` 与旧几何 | 工作台人工对照 P0.5 样张后 `--update-goldens` 固化 32 张 |
| 4 | `feat(widgetbook): 动作工作台` | `lib/widgetbook/avatar_workbench.dart`:knob 选 clip / 定帧 t 滑杆 / 播放速率 / 两个小人并排(seed 0 与 0.5)/ 46·60·78·200px 四档 / 剪影模式(纯白无 chip) | 手动 |
| 5 | `docs(avatar): P1 收尾` | token 调整(1.5)、STATUS.md 行、README 帧同步规范补「clip 数据」一条 | — |

### 1.5 token 决议(需确认)

- `CoFitMotion.avatarWindup / avatarFinish / avatarLoopPaused / bobPeriod` **保留**(全局 UI 节奏)。
- `avatarLoopStrength / Cardio / Core / Flexibility` 4 个 **删除**,周期随 clip 数据走:clip 是「内容」(和 #14a 的关键帧角度一样),不是设计 token;32 个动作各建 token 没有意义。此约定写进 design-tokens skill 的「不算 token 的数值」一节。
- 几何常量(80×100 视框、骨骼 rest 矩形)留在 `Rig` 里,同理视为内容。

---

## P2 动作贯通 + 32 个 clip + 卡片 SSOT(4–6 天)

### 2.1 `motionId` 数据流(逐文件)

| 层 | 文件 | 改动 |
|---|---|---|
| 卡片实体 | `action/domain/entity/action_template_card.dart` | `+ String? motionId`(copyWith 同步) |
| 模板仓库 | `action/data/firebase_action_template_repository.dart` | 读可选 `motionId` |
| 自建卡仓库 | `action/data/firebase_custom_card_repository.dart` | 读写可选 `motionId`(**写时 null 则不写键**,配合 rules `hasOnly`) |
| 自建卡 usecase | `usecase/create_custom_card_usecase.dart`、`update_custom_card_usecase.dart` | `+ motionId` 参数;校验必须在 `MotionClipLibrary.ids` 内 |
| 活动状态 | `room/domain/entity/user_activity_status_entity.dart` | `+ String? motionId`(fromMap/toMap),`actionKey` 不动 |
| 打牌 | `action/domain/start_template_card_action_usecase.dart`、`provider/own_action_session_notifier.dart`(3 处构造 status) | 写入 `motionId: card.motionId` |
| 会话恢复 | `pending_session_snapshot.dart` + 两个 pending 仓库 | 快照带 `motionId`,被杀恢复后 presence 不丢动作 |
| 打卡日志 | `action_session_record.dart` + rules `sessions` | `+ motionId`(可选,给以后统计「做过哪些动作」;rules 需放行可选键) |
| 房间场景 | `room/presentation/widget/room_scene.dart` | `_motionId(member)` 透传 |
| 气泡 | `room/presentation/widget/avatar_bubble.dart` | `+ motionId`,传给 sequencer |
| 动画指令 | `avatar/domain/entity/avatar_motion.dart` | `+ String? motionId` |
| 编排 | `avatar_motion_sequencer.dart` | `onLogicalState(..., motionId)`;motionId 变化也算 changed(同类型换动作要重启 loop) |
| 渲染 | `motion_clip_library.resolve` | motionId → clip;未命中回类型原型(老客户端 / 未知动作) |

**兼容矩阵**

| 发送端 | 接收端 | 结果 |
|---|---|---|
| 新(带 motionId) | 旧 | 旧客户端忽略未知键,按 `actionKey` 类型原型播 |
| 旧(无 motionId) | 新 | `motionId == null` → 类型原型,与现在一致 |
| 新 | 新,但接收端版本没有该 clip | `resolve` 未命中 → 类型原型 |

### 2.2 rules diff(走 CI,先给用户看)

```
users/{uid}/cards:   hasValidCustomCardShape 的 hasOnly 列表 + 'motionId';
                     hasValidCustomCardValues + (!data.keys().hasAny(['motionId']) || isNonEmptyString(data.motionId))
users/{uid}/sessions: 同样放行可选 'motionId'
card_templates:      只读,不改
```

### 2.3 默认卡 SSOT(与 P1 并行,0.5 天)

| 文件 | 内容 |
|---|---|
| `firestore/card_templates.json` | [default_card_templates.md](default_card_templates.md) §3 的 32 条,字段 `id,name,type,ablyActionId,motionId,defaultDurationSec,intensityBaseline{label},equipment,order` |
| `tool/seed_card_templates.mjs` | firebase-admin;读 JSON → 事务内 `set` 全部 + 删除不在 JSON 的文档;`--dry-run` 打印 diff;`package.json` 放 `tool/`(不污染 Flutter 根) |
| `.github/workflows/deploy-card-templates.yml` | 复制 deploy-rules.yml,`paths: ['firestore/card_templates.json']`,`node tool/seed_card_templates.mjs --project cofit-lmdyd` |
| `usecase/seed_default_decks_usecase.dart` | 种子改固定 id 列表(§4),缺卡跳过;单测补「缺卡不崩」 |
| `action/presentation/widget/library_tab_body.dart` | 牌库按 `order` 排序(现在是 Firestore 自然序) |

**前置**:线上现有模板清单(用户贴)或确认全量覆盖;`FIREBASE_SERVICE_ACCOUNT` 的角色含 Firestore 写(部署 rules 用的 `Firebase Admin` 角色已够)。

### 2.4 道具 Prop 与 32 个 clip 的生产

```dart
enum Prop { dumbbell, mat, rope, kettlebell }
/// 道具挂在某骨骼上,随骨骼动;P3 的 propSkin 只换它的颜色。
class PropPlacement { final Prop prop; final Bone anchor; final Offset offset; final double rotDeg; }
```

生产顺序按类型分 4 批,每批 8 个,**每批结束做一次剪影测试**(widgetbook 剪影模式,46px,并排同类型 8 个,3 人里 2 人能认出):

| 批 | clip | 预计 |
|---|---|---|
| 1 力量 | squat ✓, lunge, pushup, glute_bridge, wall_sit, biceps_curl🏋, shoulder_press🏋, calf_raise | 1 天 |
| 2 有氧 | jumping_jack, run_in_place ✓, high_knees, burpee(三段 basePose 切换,用 keys 的 step 曲线), mountain_climber, jump_rope(绳 = 道具,绕 root 画椭圆弧), skater, march | 1.5 天 |
| 3 核心 | plank ✓, side_plank, crunch, bicycle_crunch, russian_twist, dead_bug, bird_dog, leg_raise | 1 天 |
| 4 柔韧 | neck_stretch ✓, cat_cow, downward_dog, child_pose, forward_fold, hip_stretch, side_bend, breathing(torso.scale 1→1.08) | 1 天 |

写一个新 clip 的样子(jumping_jack,约 15 行):

```dart
const jumpingJack = MotionClip(
  id: 'jumping_jack', rig: RigView.front, period: Duration(milliseconds: 700),
  tracks: {
    Bone.root: Track.keys([Key(0, dy: 0), Key(.5, dy: -4), Key(1, dy: 0)]),
    Bone.legL: Track.keys([Key(0, rotDeg: 0), Key(.5, rotDeg: -22), Key(1, rotDeg: 0)]),
    Bone.armL: Track.keys([Key(0, rotDeg: 10), Key(.5, rotDeg: 165), Key(1, rotDeg: 10)]),
  },
  mirrors: [Mirror(Bone.legR, from: Bone.legL, negateRot: true), Mirror(Bone.armR, from: Bone.armL, negateRot: true)],
  effects: [ClipEffect.aura(rx: 17)],
);
```

### 2.5 自建卡「动作」选择(0.5 天)

- `custom_card_form_sheet_view.dart`:类型行下新增「动作」行 = 当前选中 clip 名 + 右侧 46px 实时预览小人;点击弹 `MotionPickerSheet`(`action/presentation/widget/motion_picker_sheet.dart`):按类型分组网格,每格 46px 小人 loop + 名称;默认选中该类型原型。
- 切换类型时若当前 motionId 不属于该类型 → 重置为该类型原型。
- 卡面(`card_face_preview.dart`、`action_card.dart`)**暂不**显示动作预览(性能:牌库一屏十几张卡各跑 60fps 不划算);卡详情 sheet(`card_detail_sheet_view.dart`)加一个 78px 预览。

### 2.6 测试

- `motion_clip_library_test.dart`:32 个 id 唯一、每个 clip 的 mirror 源骨骼存在于其 rig、period > 0、loop clip `sample(0)==sample(1)`。
- `user_activity_status_entity_test.dart`:motionId 往返;缺键 → null。
- `avatar_motion_sequencer_test.dart`:同状态换 motionId → changed。
- golden:新增 32 个 clip 各 t=.5 一张(防回归,不是像素验收)。

---

## P3 形象自定义:免费层(5–7 天)

### 3.1 `AvatarConfig` 实体与迁移

`avatar/domain/entity/avatar_config.dart`(freezed,字段见设计 §5.1)。

- `fromMap`:`v` 缺失或 `presetId` 存在 → `AvatarConfig.defaults`;未知物品 id **保留原值**(不要在读取时丢掉,否则老客户端一保存就把新物品擦掉),渲染时按槽位默认画。
- `toMap`:null 槽位不写键。
- `UserProfileEntity.avatarConfig: Map` → `AvatarConfig`;`toMap/fromMap`、`complete_onboarding_usecase`、`update_profile_usecase` 随改;`profile` 现有单测更新。
- `usecase/update_avatar_config_usecase.dart`:写 `users/{uid}.avatarConfig` + `updatedAt` → 成功后 `AblyRuntimeNotifier.reassertPresence()`。

rules diff:

```
hasValidProfileValues: data.avatarConfig is map
  && data.avatarConfig.v is int
  && data.avatarConfig.keys().hasOnly(['v','body','bodyColor','pattern','limbBand','face','headwear','eyewear','handheld','propSkin','aura','celebration'])
  && data.avatarConfig.body is string && data.avatarConfig.bodyColor is string
```
(其余槽位可选,值类型 string 由 `hasOnly` + 客户端保证;rules 不校验 id 是否在目录内——目录随版本变。)

### 3.2 目录与物品

```dart
enum AvatarSlot { aura, pet, body, pattern, bodyColor, limbBand, face, eyewear, headwear, handheld, propSkin, celebration }

sealed class Unlock {
  const factory Unlock.free() = _Free;
  const factory Unlock.sweat(int cost) = _Sweat;
  const factory Unlock.level(int level) = _Level;
  const factory Unlock.achievement(AchievementId id) = _Achievement;
  const factory Unlock.monthly(String yyyyMM, int sessions) = _Monthly;
  const factory Unlock.pack(String packId) = _Pack;          // P4
  const factory Unlock.subscription() = _Subscription;       // 预留
}

class AvatarItem {
  final String id; final AvatarSlot slot; final String nameZh;
  final Unlock unlock; final PartPainter painter;             // painter 在 presentation 层注册,entity 只存 id
}
```

目录(`avatar/data/avatar_catalog.dart`,const)首批免费层 **12 件 + 默认**:

| slot | id | unlock |
|---|---|---|
| bodyColor | gray50(默认)、lime、coral、amber、blue、gray500 | 前 3 个 free(onboarding 可选),后 3 个 sweat 30/30/60 |
| pattern | stripe、dots | sweat 60 / level 2 |
| body | round | level 3 |
| headwear | band_lime(free)、band_coral(sweat 45)、cap(level 2)、cat_ears(achievement streak7) |
| eyewear | sport_glasses(sweat 90) |
| aura | sparkle(achievement streak30)、ring_double(level 4) |
| celebration | fireworks(sweat 120) |
| limbBand | wrist_lime(monthly 2026-12, 12 次) |

`PartPainter` 注册表 `avatar/presentation/renderer/part_painters.dart`:`Map<String itemId, PartPainter>`;`PartPainter.paint(Canvas, Bone bone, BoneDef def, LookColors colors)` 在骨骼局部坐标画。颜色只用 `CoFitPalette` 命名色,物品里存色名 → `LookColors.resolve(name)`。

### 3.3 渲染集成与状态色迁移(#6c)

- `AvatarAppearance` 改为 `AvatarLook{config, bodyColor(已解析), ringColor?, auraColor, auraOpacity, inactive}`;`AvatarRenderer.build(look: ...)`——这是接口的唯一签名变化,调用点 3 处(`avatar_bubble`、`idle_avatar_figure`、widgetbook)。
- `RigAvatarPainter` 绘制顺序:aura → (pet) → 每根骨骼 [body/pattern/bodyColor 合一画 → limbBand] → face → eyewear → headwear → handheld(仅 idle/paused)→ props(propSkin 着色)→ celebration(仅 finish)。
- `avatar_bubble._resolveAppearance` 改为设计 §5.6 表:身体 = config.bodyColor;头环:自己 lime@strong,好友 active lime / paused amber / idle 无;idle 好友整体 `avatarInactive`;光圈规则不变。**前置:#6c 设计确认**。
- 性能:`PartPainter` 的 `Path` 用 `static final` 缓存;每个 `VectorAvatarFigure` 外包 `RepaintBoundary`(现在没有,补上);好友小人在 `AppLifecycleState != resumed` 时 `controller.stop()`。

### 3.4 presence 携带形象

- `ably_state_machine.dart` 两处组 data(enter 与 reassert)加 `'avatar': config.toMap()`(来源 `ownAvatarConfigProvider`,与 `ownNicknameProvider` 同构)。
- `RoomPresenceMember.fromMap` 读 `data['avatar']` → `AvatarConfig?`;null → defaults。
- `room_scene` → `AvatarBubble(config: member.avatar ?? defaults)`。
- 「新装上身」:`AvatarBubble.didUpdateWidget` 检测 `config` 变化且状态为 idle → 播一次 `windup` 的 burst(不走 sequencer 的业务状态,加一个 `flashOnce` 标志)。

### 3.5 经济与养成(全部客户端现算,纯 usecase,可单测)

数据源只有 `users/{uid}/sessions`(已有流)与 `users/{uid}/entitlements`(新)。

```dart
class AvatarProgress {            // usecase/compute_avatar_progress_usecase.dart 的输出
  final int totalMinutes;         // Σ durationSec/60(向下取整,与历史页一致用 round 则改历史页)
  final int level;                // 阈值 [0, 60, 300, 1000, 3000] 分钟 → Lv1..5
  final int streakDays;           // 本地时区,连续有 ≥1 条 completed 的天数,今天没练不算断(到明天才断)
  final int sweatEarned;          // = totalMinutes × 1
  final int sweatSpent;           // Σ entitlements(source == sweat).cost
  final int sweatBalance;
  final Set<AchievementId> achievements;
  final Map<String yyyyMM, int> monthlySessions;
}
```

成就首批(都能从 sessions 算):`streak3 / streak7 / streak30 / strength50 / cardio50 / core50 / flexibility50 / rooms5`(在 5 个不同 roomId 打过卡)。设计稿里「与 5 个不同的人同房运动」**sessions 里没有同房成员数据,先不做**。

`UnlockResolver.isUnlocked(item, progress, entitlements)`:free → true;sweat → entitlements 含该 itemId;level/achievement/monthly → progress 判定;pack → entitlements 含 packId。

### 3.6 `entitlements` 集合

```
users/{uid}/entitlements/{docId}
  { itemId? | packId?, source: 'sweat' | 'appstore', cost?: int, transactionId?, originalTransactionId?, purchasedAt }
rules: read/create/delete 仅本人;update false;
       create 校验 source in ['sweat','appstore'];source=='sweat' ⇒ cost is int && cost >= 0 && itemId 非空;
       source=='appstore' ⇒ packId 非空 && transactionId 非空
```

- `usecase/redeem_sweat_item_usecase.dart`:余额 ≥ cost → 写 entitlement(docId = itemId,`set` 不覆盖已存在 → 幂等)。
- `firebase_user_data_eraser.dart` 的 `_subcollections` 加 `'entitlements'`(账号删除顺序约束不变);`delete_account_usecase` 单测补该子集合。

### 3.7 UI(需设计稿:编辑器、#6c、onboarding 快捷色)

| 页面/组件 | 文件 | 内容 |
|---|---|---|
| 形象编辑器 | `avatar/presentation/view/avatar_editor_page_view.dart` | 上:`AvatarPreview`(200px 小人 + 动作 chip 行:待机 / 随机动作 / 完成)+ 汗滴余额 + Lv;下:槽位 tab(`SlotTabs`)+ `ItemGrid`。本地 `draft` 状态试穿;「保存」一次写入;未保存返回 → `showCoFitConfirmSheet` |
| 物品格 | `avatar/presentation/widget/item_tile.dart` | 四态:已装备(lime 描边)/ 已拥有 / 可兑换(汗滴价)/ 锁定(等级、成就、月度、形象包说明) |
| 我的页 | `auth/presentation/widget/my_page_body.dart` | `onEditAvatar` 接回调;hero 改为真实 config(`IdleAvatarFigure` 加 `config` 参数) |
| Onboarding | `profile/presentation/view/onboarding_page_view.dart` | 小人下方 3 个免费身体色圆点;选中即写 config |
| 邀请预览 | `invite_preview_sheet_view.dart` | 中央小人用邀请人 `users/{uid}.avatarConfig`(已有昵称读取处顺带读);两侧剪影不变 |
| 房间 | `avatar_bubble.dart` | #6c 配色 |

### 3.8 测试

- `avatar_config_test.dart`:往返、旧 `{presetId}` 迁移、未知 id 保留、null 不写键。
- `compute_avatar_progress_usecase_test.dart`:streak 跨午夜/时区、等级阈值边界、余额不为负、成就判定。
- `unlock_resolver_test.dart`:7 种 unlock。
- `room_presence_member_test.dart`:avatar 缺失 → defaults。
- widget:编辑器试穿不写库、保存写一次、未保存返回弹确认。
- golden:默认形象 + 每件免费物品各一张(idle,t=0)。

---

## P4 付费(3–4 天 + App Store Connect)

### 4.1 技术接入

- 依赖:`in_app_purchase` + `in_app_purchase_storekit`;iOS 启动时 `InAppPurchaseStoreKitPlatform.enableStoreKit2()`。
- `avatar/data/store_kit_purchase_gateway.dart`(实现 `domain/purchase_gateway.dart`):
  - `queryPacks(ids)` → `ProductDetails`(本地化价格直接显示,不自己写 ¥);
  - `buy(packId)` → 监听 `purchaseStream`;`purchased/restored` → 校验 → 写 entitlement(docId = packId,`set` 幂等)→ `completePurchase`;`error/canceled` → 对应 UI;
  - `restore()` → `restorePurchases()`;另外冷启动时直接读 Firestore `entitlements`(两条路都通)。
- 校验(阶段一):StoreKit 2 路径只会把 Apple 验签通过的交易交给 App;保存 JWS(`verificationData.serverVerificationData`)到 entitlement 的 `receipt` 字段以备阶段二服务端复核。**不要**自己在客户端解 JWS 判断真伪——没有意义,改 Firestore 更容易。
- 目录:`Unlock.pack(packId)`;`AvatarPack{id, productId 'com.passerbo.cofitapp.avatar_pack_<id>', items, exclusiveItemId}`。
- 首批 2 个包(各含 1 个庆祝特效 + 1 个光圈 + 2–3 件穿戴):`neon`(霓虹:lime 渐变花纹、双环光圈、烟花庆祝、荧光护腕)、`cozy`(居家:毛线帽、圆形态、暖光光圈、比心庆祝)。

### 4.2 Remote Config

| key | 默认 | 用途 |
|---|---|---|
| `avatar_store_enabled` | false | 总开关;审核通过前关闭,编辑器里不出现「形象包」入口(避免 2.1「功能不可用」) |
| `avatar_store_featured` | "" | 逗号分隔 packId,周推荐位 |
| `avatar_pack_<id>_enabled` | true | 单包下架 |

进 `FeatureFlags` 字段 + `defaultsMap`。

### 4.3 UI

- `avatar/presentation/view/avatar_pack_sheet_view.dart`:包内物品一览(每件 78px 预览)+ 价格按钮 + 「恢复购买」文字按钮 + 购买中禁用态 + 失败 toast。
- 编辑器 `ItemTile` 锁定态「来自 ◯◯ 形象包 ›」→ 打开该 sheet。
- 法务:`docs/legal/terms.md` 补虚拟物品条款(不可退换、随账号删除失效);账号删除确认文案提一句「已购形象随账号删除失效」。

### 4.4 App Store Connect 清单(用户操作)

1. Agreements:**Paid Applications 协议签署 + 税务/银行信息**(没签之前 IAP 产品查不到,沙盒也不行)。
2. 创建 2 个非消耗型 IAP:product id 如上、价格档、本地化名称/描述、审核截图。
3. Sandbox 测试账号 1–2 个;真机登录沙盒账号测购买、取消、恢复、重装后恢复。
4. 提审备注写明:形象包为纯装饰,恢复购买入口位置。
5. 隐私营养标签:新增「购买记录」(与用户关联)。

### 4.5 测试

- `purchase_gateway` 用 fake 实现跑 usecase 单测:购买成功写权益一次、重复事件幂等、取消不写、恢复合并。
- 沙盒手测脚本(docs 里列步骤),结果记 STATUS.md。

---

## 横切事项

### 文档回写

| 时点 | 文件 | 内容 |
|---|---|---|
| P1 末 | README §关键帧同步规范 | 加第 7 条「动作是 clip 数据,渲染从 pose(t) 采样」 |
| P2 末 | README §小人动作动画 | 重写:删「只按 4 类型通用原型」,改为「每卡 motionId,类型原型兜底」+ 32 clip 表 |
| P2 末 | CLAUDE.md Firestore 集合行 | `card_templates` 注明「SSOT 在 firestore/card_templates.json,CI 部署」 |
| P3 末 | project_overview.md、flows_status.md | avatar 特性从「占位」改为现状;新流程 F?「编辑形象」 |
| 每阶段 | STATUS.md | 屏幕进度 + 决议日志 |

### 风险与对策

| 风险 | 对策 |
|---|---|
| P1 golden 因抗锯齿/字体环境在不同机器上不一致 | golden 只在 CI 或同一台 Mac 生成;画面纯几何无字体;容差用 `matchesGoldenFile` 默认(0 容差)先试,不行再 `GoldenFileComparator` 自定义 0.1% |
| 形象重做牵动品牌资产(图标/启动图/登录页品牌区/邀请卡剪影) | 列入 P3 末「品牌资产跟随」子任务(`docs/brand/` SVG 源重做 + rsvg-convert 导出);里程碑 B 之前仍用旧图标 |
| 新形象的 8 个基础状态在 P0.5 只有关键帧表没有实物,P1 才能看到动起来的样子 | 探索页已用 CSS 关键帧验证过四个代表动作;P1 第 3 步在工作台里逐个对照,偏差回 P0.5 改表而不是改代码 |
| 32 个 clip 手工调帧耗时超预期 | 批次制 + 剪影测试门槛;允许前 2 批先上,后 2 批跟版本 |
| 46px 下动作辨识度不够 | 道具 + chip 文字兜底;必要时好友小人尺寸 token `sizeFigureFriend` 46 → 52(设计确认) |
| 状态色迁移改变 #6b 定稿 | 必须拿到 #6c 再做 3.3;P3 其余部分不受阻 |
| 汗滴客户端现算可被篡改 | 接受(纯装饰);阶段二 Functions 校验 |
| IAP 审核被拒(2.1 / 3.1.1) | 总开关默认关;提审版本自带可购买的真实物品;恢复购买入口明显 |
| 旧客户端把新 config 擦掉 | 读取时保留未知 id(3.1);rules `hasOnly` 列表一次给全 12 个槽位 |

### 顺序与里程碑

```
周 1   P1(3d)  ──┐
       卡片 SSOT(0.5d,并行)│
周 2   P2 批 1–2 + 贯通 ──┤  ← 里程碑 A:房间里能看到 16 种不同动作
周 3   P2 批 3–4 + 自建卡选动作 ─┤  ← 里程碑 B:32 动作 + 新默认卡上线(可发一版)
周 4–5 P3 ─────────────┤  ← 里程碑 C:免费层形象 + 汗滴/等级/成就(可发一版)
周 6   P4 ─────────────┘  ← 里程碑 D:付费包(等 ASC 协议与审核)
```

里程碑 B 与 C 各自可独立发版;D 依赖用户完成 4.4 的 ASC 操作。

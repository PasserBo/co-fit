# 豆豆 · 骨骼规格与基础状态关键帧(v0 · 2026-11-04 · 待用户确认)

> P0.3–0.5 的产物。可动版本:[avatar_bean_sheet.html](avatar_bean_sheet.html)(本表每个数值都在那里动过并看过)。
> 确认后这张表就是 P1 的 `Rig.front / Rig.side` 常量与 `motion_clips/core_states.dart` 的来源;改数值先改这里,再改代码。

## 0. 坐标系

- 视框 **80 × 100**(与 #14a 相同,`VectorAvatarFigure.aspectRatio = 0.8` 不变),y 向下;**地面 y = 90**;root 枢轴 (40, 88)。
- 形体高(头顶 y7 → 脚底 y89)= 82/100 视框。token `sizeFigure*` 定义的是形体高,换算视框高 = 形体高 × 100/82(现在是 100/60,P1 改)。
- 角度:顺时针为正(Flutter `canvas.rotate` 同向)。四肢的 rest 方向是「垂直向下」,`rot` 是相对 rest 的偏转。

## 1. 骨骼表(14 根,正面;侧面见 §3)

| 骨骼 | 父 | 枢轴 (x,y) | rest 几何(圆角矩形 x,y,w,h;r = 短边/2) | 自由度与上限 |
|---|---|---|---|---|
| root | — | (40, 88) | — | dx dy 任意;rot ±10°;scale 0.9–1.16(挤压拉伸体积守恒:sx = 1/sy) |
| pelvis | root | (40, 70.5) | — | dy 0–10(深蹲下沉) |
| spine | pelvis | (40, 68) | 蛋体 path(§1.1) | rot ±30°;scaleY 0.94–1.08(sx 互补) |
| head | spine | (40, 31) | 无几何(面部 + crown 挂点) | rot ±20° |
| uarmL | spine | (15.25, 39) | (12.5, 39, 5.5, 10) | rot −180…+180 |
| farmL | uarmL | (15.25, 50) | (12.5, 51, 5.5, 9) | rot −150…+20(肘只向一侧弯) |
| uarmR | spine | (64.75, 39) | (62, 39, 5.5, 10) | 镜像 uarmL |
| farmR | uarmR | (64.75, 50) | (62, 51, 5.5, 9) | 镜像 farmL |
| thighL | pelvis | (33, 70.5) | (30, 70.5, 6, 8) | rot −100…+40 |
| shinL | thighL | (33, 79) | (30, 79.5, 6, 7) + 脚垫 (28, 86, 10, 3) | rot 0…+120(膝只向后弯) |
| thighR | pelvis | (47, 70.5) | (44, 70.5, 6, 8) | 镜像 |
| shinR | thighR | (47, 79) | (44, 79.5, 6, 7) + 脚垫 (42, 86, 10, 3) | 镜像 |

绘制顺序(后画的在前):远侧腿 → 近侧腿 → [spine:远侧臂 → 蛋体 → 花纹 → 状态描边 → 近侧臂 → head(面部 → 眼镜 → 头饰)]。正面时 L 先于 R 无所谓(不重叠)。

### 1.1 蛋体 path

```
M40 7 C 59 7, 61 29, 60 48 C 59 63, 50 68, 40 68 C 30 68, 21 63, 20 48 C 19 29, 21 7, 40 7 Z
```
高 61(y 7–68),最宽 40(y≈48),顶部略尖、底部圆。Flutter 里用 `Path.cubicTo` 照抄。

### 1.2 悬浮分段的「缝」

四肢每段用**背景色描边 1.4**(`paint-order: stroke`,Flutter 里先画 bg 色放大 0.7 的同形,再画本体)。缝让四肢在与蛋体重叠时(侧视手臂、抱膝)仍可分辨——设定稿里实测:侧视手臂贴在蛋体上,没有缝就整条消失。

## 2. 挂点 Socket(9 个)

| 挂点 | 跟随骨骼 | 正面 (x,y) | 侧面 (x,y) | 用途 |
|---|---|---|---|---|
| crown | head | (40, 7) | (40, 7) | 发带 / 帽 / 猫耳 |
| face | head | (40, 29) | (48, 29) | 眼 / 面罩 / 眼镜(侧面单眼) |
| chest | spine | (40, 50) | (44, 50) | 胸前图案 |
| back | spine(画在蛋体后) | (40, 40) | (28, 40) | 翅膀 / 背包(预留) |
| handL / handR | farmL / farmR 末端 | (15.25, 60) / (64.75, 60) | (46, 60) near / far | 手持、哑铃 |
| footL / footR | shinL / shinR 末端 | (33, 88) / (47, 88) | (40, 88) near / far | 鞋袜 / limbBand |
| ground | 无(root 之外) | (40, 90) | (40, 90) | 光圈 / 垫子 |

## 3. 视角

- `Facing.front`:上表原样。
- `Facing.side`(朝右):同一棵树,L→near、R→far;**肩前移到 (46, 39)**,臂几何 (43.25, 39, 5.5, 10)/(43.25, 51, 5.5, 9);髋 (40, 70.5),腿几何 (37, 70.5, 6, 8)/(37, 79.5, 6, 7),脚垫 (36, 86, 11, 3)(前伸 4,方向线索);**远侧腿整体 x −1.5**(否则与近侧腿完全重合);远侧肢体 opacity 0.8;单眼 (48, 29)。
- 朝左 = root scaleX(−1)(以 x=40 为轴),免费。
- clip 声明自己的 facing;同一 clip 不混用两种视角。

## 4. 面部、状态、配色

- 默认面部:两点眼 r 1.7,(34, 29) / (46, 29),色 gray-900;无嘴。面罩 / 无脸 / 其他表情 = `face` 槽位物品。
- **状态描边**(替代 #6b 的头环):沿蛋体 path 的 2.4 描边。自己 = lime @90 常亮;好友 运动中 lime / 暂停 amber / 挂机 无。
- 光圈(ground):运动中 类型色 @28、暂停 amber @25、待机 主体色 @18;rx 17,卧姿 clip 26。
- 暂停:整体 opacity 0.75;挂机好友:整体 0.70(`avatarInactive`)。
- 身体色默认 gray-50;物品只用 `CoFitPalette` 命名色。

## 5. 八个基础状态关键帧(P1 验收样张)

> 2026-11-21 增补三条(change `add-home-sheet`):站立待机、上台、下台。位移由房间页的位置层负责,clip 只有姿势;时间点与 `motion.stage*` token 对应。

记法:`骨骼: 0% → 50% → 100%`(loop)或带百分比的多段;缓动默认 ease-in-out;`mirror` 表示右/远侧 = 左/近侧取反。周期是 clip 数据(见 token 决议),×1 动画播完回调编排器。

| 状态 | 视角 | 周期 | 轨道 | 特效 |
|---|---|---|---|---|
| **idle** | front | 2.4s loop | root.dy 0 → −5 → 0;spine.scale (1,1) → (.985,1.03) → (1,1) | aura rx17 |
| **windup** ×1 | front | 0.4s | root.scale 1 → 1.16 → 1(overshoot,cubic-bezier(.34,1.56,.64,1));uarmL.rot 0 → 40 → 0,uarmR mirror | burst ring 0.5 → 2 淡出 |
| **squat**(力量原型) | side | 1.3s loop | pelvis.dy 0 → 7 → 0;thigh.rot 0 → −82 → 0(near=far);shin.rot 0 → 88 → 0;spine.rot 0 → 24 → 0;uarm.rot 0 → −95 → 0;farm.rot 0 → −8 → 0;head.rot 0 → −20 → 0 | aura rx17 |
| **run**(有氧原型) | side | 0.6s loop | root.dy 2 倍频 hop:0 → −2.5 → 0 → −2.5 → 0;spine.rot 常量 8;thighN.rot −32 → 32 → −32,thighF mirror;shinN.rot 10 → 55 → 10,shinF 55 → 10 → 55;uarmN.rot 35 → −35 → 35,uarmF mirror;farm.rot 常量 −70 | aura rx17 |
| **plank**(核心原型) | side | 0.9s loop | basePose:root 绕 (40,50) rot 90 + 平移 (−3, 20);uarm.rot −90(手贴地,IK 目标 = ground);head.rot −12;root.dy 0 → 1.6 → 0 微颤 | aura rx26 |
| **stretch**(柔韧原型) | front | 2.6s loop | spine.rot 0 → −16(40%)→ −16(60%)→ 0(顶点停 20%);head.rot 0 → 8 → 8 → 0;uarmR.rot 常量 −150(过头),farmR.rot −20;thighL.rot 常量 10,thighR −10(站宽) | aura rx17 |
| **paused** | front | 3.0s loop | root.rot −5 → 5 → −5;整体 opacity .75 | 描边 amber,aura amber @25 |
| **finish** ×1 | front | 1.1s | root.dy 0 → −16(27%)→ 0(55%)→ −6(70%)→ 0(85%);spine.scale (1,1) → (.94,1.08)(18%)→ (1.06,.94)(55%)→ (1,1)(73%);uarmL.rot 0 → 150(35%,easeOutBack)保持,uarmR mirror | burst ×2(第二个延迟 0.12s) |
| **idle_stand**(今日面板台上) | front | 2.4s loop | 无 root.dy;spine.scale (1,1) → (.985,1.03) → (1,1) | aura rx17 |
| **board** ×1(上台) | front | 0.52s | spine.scale 蓄力 (1.1,.88)(17%)→ 腾空 (.95,1.07)(30–65%)→ 触地 (1.12,.86)(78%)→ (.98,1.03)(92%)→ (1,1);uarmL.rot 0 → −8(17%)→ 36(35–65%)→ 16(80%)→ 0,uarmR mirror | 触地 burst(65% 起) |
| **leave** ×1(下台) | front | 0.48s | spine.scale 蓄力 (1.12,.86)(19%)→ 腾空 (.94,1.08)(33–70%)→ (1,1)(83%);uarmL.rot 0 → −8(19%)→ 30(36%)→ 0(83%),uarmR mirror | aura rx17 |

`run` 的膝弯和 `plank` 的 basePose 是新形象相对 #14a 多出来的两个表达手段(关节、IK),其余与 README §小人动作动画 的意图一致,只是数值按新比例重调。

## 6. 设定稿阶段实测记录

| 发现 | 处理 |
|---|---|
| 腿 6+5.5 太短,深蹲像整体下沉 | 腿改 8+7,髋移到蛋体下沿外 2.5 |
| 侧视手臂贴轴线,整条藏进蛋体,俯卧撑看不见手 | 肩前移 6;四肢加背景色缝(§1.2) |
| 侧视近/远腿完全重合,看起来只有一条腿 | 远侧腿 x −1.5 |
| SVG 内嵌 `<style>` 全文档作用域,多图强调色互相覆盖 | 设定稿页改内联 fill;对 Flutter 无影响,但提醒:物品颜色必须是实例数据,不能是全局样式 |

## 7. 引擎路线(P0.6)

设定稿全部用「几何 + 关键帧」做成并验证通过,等价于纯 Dart clip 数据;没有出现需要网格形变的动作。**建议直接定纯 Dart**(方案 B),Rive 留作将来高级皮肤的可选渲染器。若用户仍想比较,P1 第 3 步前各花半天做 idle + squat 的两路原型。

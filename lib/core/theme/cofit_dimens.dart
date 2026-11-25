import 'package:flutter/widgets.dart';

/// 非颜色设计 token 的 Dart 承载。
/// 事实源:lib/core/theme/tokens/cofit.tokens.json — 修改流程见 design-tokens skill(JSON 先行)。
/// 常量名与 JSON path 对应:spacing.md → spacingMd。
abstract class CoFitDimens {
  // spacing.* — 间距刻度(4 基数)
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 20.0;
  static const spacing2xl = 24.0;
  static const spacing3xl = 32.0;

  // radius.*
  static const radiusXs = 4.0;
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;

  // borderWidth.*
  static const borderWidthHairline = 1.0;
  static const borderWidthFocus = 1.5;

  /// 今日进度环线宽
  static const borderWidthProgressRing = 4.0;

  // size.*
  static const sizeCardTypeBar = 4.0;
  static const sizeCardIconBlock = 26.0;
  static const sizeRemoveBadge = 19.0;
  static const sizeRemoveBadgeOffset = 6.0;
  static const sizeCardIcon = 14.0;
  static const sizeCheckBadge = 18.0;
  static const sizeMinTapTarget = 44.0;
  static const sizeLibraryCardItem = 112.0;
  static const sizeSectionDot = 9.0;
  static const sizeBannerIcon = 30.0;
  static const sizeDeckStackWidth = 34.0;
  static const sizeDeckStackHeight = 38.0;
  static const sizeDeckStackCardWidth = 22.0;
  static const sizeDeckStackCardHeight = 30.0;
  static const sizeDeckCardThumb = 52.0;
  static const sizeDockItem = 26.0;
  static const sizeFigureFriend = 46.0;
  static const sizeFigureSelf = 60.0;
  static const sizeAuraFriend = 48.0;
  static const sizeAuraSelf = 70.0;
  static const sizeFanCardWidth = 70.0;
  static const sizeFanCardHeight = 98.0;
  static const sizeFanHeight = 214.0;
  static const sizeFanPivotRadius = 320.0;
  static const sizeDeckChipBottom = 178.0;
  static const sizePopoverWidth = 196.0;
  static const sizeHudRing = 34.0;
  static const sizeRoomDot = 6.0;
  static const sizeRoomDotActive = 20.0;
  static const sizeFigureHero = 78.0;
  static const sizeHeroGlow = 128.0;
  static const sizeAuthFormMaxWidth = 360.0;
  static const sizeCardPreview = 88.0;
  static const sizeCardPreviewCompact = 76.0;
  static const sizeCardPreviewLg = 120.0;
  static const sizeTypeBarHeight = 28.0;
  static const sizeHistoryChartHeight = 34.0;
  static const sizeHistoryChartBar = 7.0;
  static const sizeInviteBand = 86.0;
  static const sizeSuccessBadge = 44.0;
  static const sizeBrandStage = 120.0;
  static const sizeAuthGlow = 110.0;
  static const sizeLoginFanCardWidth = 30.0;
  static const sizeLoginFanCardHeight = 42.0;

  /// 今日面板(add-home-sheet):台上小人脚底高出面板上沿的距离 / 把手横条宽
  static const sizeStageFootInset = 6.0;
  static const sizeSheetGrabberWidth = 36.0;

  /// 面板展开时手牌下沉的距离
  static const sizeFanSink = 48.0;

  /// 今日进度环直径
  static const sizeProgressRing = 44.0;

  // blur.*
  static const blurOverlay = 8.0;
  static const blurGlow = 10.0;
}

/// motion.* — 动效 token
abstract class CoFitMotion {
  /// 小人上下浮动幅度(逻辑像素)
  static const bobOffset = 5.0;

  /// 运动中光圈呼吸动画 scale 1 → 1.055
  static const breatheScale = 1.055;

  /// dock 无操作自动收起
  static const dockAutoCollapse = Duration(seconds: 5);

  /// dock 展开/收起过渡
  static const dockExpand = Duration(milliseconds: 220);

  /// 小人上下浮动周期 / 光圈呼吸周期
  static const bobPeriod = Duration(milliseconds: 2400);
  static const breathePeriod = Duration(milliseconds: 1800);

  /// 扇形聚焦/切牌过渡、打出飞卡
  static const fanTransition = Duration(milliseconds: 280);
  static const playFly = Duration(milliseconds: 420);

  /// 小人全局节奏(README §小人动作动画):起手/完成 ×1 与暂停摇摆。
  /// 各运动动作的 loop 周期是 clip 数据(avatar/presentation/renderer/clips),不是 token。
  static const avatarWindup = Duration(milliseconds: 400);
  static const avatarFinish = Duration(milliseconds: 1100);
  static const avatarLoopPaused = Duration(milliseconds: 3000);

  /// 建房成功徽章外扩光圈周期 (#20b)
  static const burstRing = Duration(milliseconds: 1800);

  /// presence 呼吸绿点周期 (#20c)
  static const shimmer = Duration(milliseconds: 2000);

  /// 新建卡片定位外发光时长 (#16a)
  static const createGlow = Duration(milliseconds: 1200);

  /// 启动 splash:入场(小人+字标淡入上浮)/ 与首页交叉淡出
  static const splashReveal = Duration(milliseconds: 600);
  static const splashFade = Duration(milliseconds: 320);

  /// 今日面板(台子)升起/降下到位时长(add-home-sheet design §8)
  static const stageRise = Duration(milliseconds: 320);

  /// 小人上台/下台:蓄力、空中、落地回弹
  static const stageCrouch = Duration(milliseconds: 90);
  static const stageHopBoard = Duration(milliseconds: 250);
  static const stageHopLeave = Duration(milliseconds: 310);
  static const stageLand = Duration(milliseconds: 180);

  /// 上台/下台 ×1 clip 总时长(= 蓄力 + 空中 + 落地/落定)
  static const avatarBoard = Duration(milliseconds: 520);
  static const avatarLeave = Duration(milliseconds: 480);

  /// 面板模块依次出现的间隔 / 单个模块淡入时长
  static const sheetModuleStagger = Duration(milliseconds: 50);
  static const sheetModuleReveal = Duration(milliseconds: 200);

  /// 完成庆祝时模块节拍间隔
  static const celebrateBeatStagger = Duration(milliseconds: 120);

  /// 回到前台后自动展开今日面板前的停顿
  static const stageAutoExpandDelay = Duration(milliseconds: 200);

  /// 今日进度的数字与进度环滚到新值
  static const progressRoll = Duration(milliseconds: 600);

  /// 达成今日目标时进度环强调一次
  static const goalReachedPulse = Duration(milliseconds: 500);

  /// 今日进度等不到庆祝节拍时直接更新的等待上限
  static const dailyProgressBeatTimeout = Duration(milliseconds: 2500);
}

/// decor.* — 装饰性绘制常量
abstract class CoFitDecor {
  /// 叠牌缩略最底张/中间张倾角(度)
  static const deckStackTiltBackDeg = -10.0;
  static const deckStackTiltMidDeg = 4.0;

  /// 虚线描边节奏
  static const dashLength = 6.0;
  static const dashGap = 4.0;

  /// 扇形手牌几何(seed v1)
  static const fanSpreadDeg = 12.0;
  static const fanFocusScale = 1.5;
  static const fanFocusLift = 120.0;
  static const fanSideOpacity = 0.55;
  static const playSwipeThreshold = 60.0;

  /// 聚焦态横向甩动切牌的速度阈值(px/s)
  static const fanFlingVelocity = 400.0;

  /// 动画节奏倍率(README §动画:慢/标准/快 → 时长 ×1.3/×1/×0.75)
  static const tempoSlow = 1.3;
  static const tempoFast = 0.75;

  /// 登录页斜插装饰卡倾角(度,±)(#19a)
  static const loginFanTiltDeg = 16.0;

  /// 小屏 375 品牌区小人缩放(#19a 附注)
  static const brandCompactScale = 0.8;

  /// 小人上台/下台弧线高出直线的距离、台上放大倍率、落地时台面下沉
  static const stageHopArc = 16.0;
  static const stageFigureScale = 1.15;
  static const stageLandDip = 3.0;

  /// 拖动把手时面板展开程度低于/高于此值,小人下台/回到台上(回差避免来回跳)
  static const stageDragLeave = 0.35;
  static const stageDragBoard = 0.6;

  /// 松手时按甩动方向判定展开/收起的速度阈值(px/s)
  static const stageFlingVelocity = 700.0;

  /// 面板展开程度超过此值模块开始出现 / 面板高度上限占屏幕高度的比例
  static const sheetModuleRevealAt = 0.7;
  static const sheetMaxHeightFraction = 0.45;

  /// 面板展开程度到此值时手牌完全淡出
  static const fanSinkFadeBy = 0.5;

  /// 起跳距离达到此值时用完整弧高,不足时等比缩小(px)
  static const stageHopArcFullDistance = 80.0;

  /// 完成 ×1 clip 第一次落地的时间点(占 avatarFinish 的比例);庆祝节拍与触感对齐它
  static const finishFirstLanding = 0.55;

  /// 达成今日目标时进度环强调的放大倍数
  static const goalReachedPulseScale = 1.18;
}

/// typography.fontWeight.* — 字重 token(字体族见 CoFitTheme)
abstract class CoFitFontWeights {
  static const heading = FontWeight.w700;
  static const label = FontWeight.w600;
}

/// typography.* — 字距等排版 token
abstract class CoFitTypography {
  /// eyebrow 小标字距(≈.08em)(#20a)
  static const letterSpacingWide = 1.0;
}

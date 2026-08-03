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

  /// 小人动作动画(README §小人动作动画 关键帧表)
  static const avatarWindup = Duration(milliseconds: 400);
  static const avatarFinish = Duration(milliseconds: 1100);
  static const avatarLoopStrength = Duration(milliseconds: 1300);
  static const avatarLoopCardio = Duration(milliseconds: 600);
  static const avatarLoopCore = Duration(milliseconds: 900);
  static const avatarLoopFlexibility = Duration(milliseconds: 2600);
  static const avatarLoopPaused = Duration(milliseconds: 3000);
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

  /// 动画节奏倍率(README §动画:慢/标准/快 → 时长 ×1.3/×1/×0.75)
  static const tempoSlow = 1.3;
  static const tempoFast = 0.75;
}

/// typography.fontWeight.* — 字重 token(字体族见 CoFitTheme)
abstract class CoFitFontWeights {
  static const heading = FontWeight.w700;
  static const label = FontWeight.w600;
}

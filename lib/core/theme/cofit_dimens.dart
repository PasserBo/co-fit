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
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;

  // borderWidth.*
  static const borderWidthHairline = 1.0;
  static const borderWidthFocus = 1.5;

  // size.*
  static const sizeCardTypeBar = 4.0;
  static const sizeCardIconBlock = 26.0;
  static const sizeRemoveBadge = 19.0;
  static const sizeMinTapTarget = 44.0;

  // blur.*
  static const blurOverlay = 8.0;
}

/// motion.* — 动效 token
abstract class CoFitMotion {
  /// 小人上下浮动幅度(逻辑像素)
  static const bobOffset = 5.0;

  /// 运动中光圈呼吸动画 scale 1 → 1.055
  static const breatheScale = 1.055;

  /// dock 无操作自动收起
  static const dockAutoCollapse = Duration(seconds: 5);
}

/// typography.fontWeight.* — 字重 token(字体族见 CoFitTheme)
abstract class CoFitFontWeights {
  static const heading = FontWeight.w700;
  static const label = FontWeight.w600;
}

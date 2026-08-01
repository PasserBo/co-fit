import 'package:flutter/material.dart';

/// CoFit Color Tokens v1 — 深色主题
/// 两层结构:CoFitPalette(基础色板,私有使用)→ CoFitColors(语义 token,组件只引用这层)。
/// 用法: `Theme.of(context).extension<CoFitColors>()!`
abstract class CoFitPalette {
  // Lime · 品牌
  static const lime200 = Color(0xFFE4F9A3);
  static const lime300 = Color(0xFFD9F57E);
  static const lime400 = Color(0xFFC8F24B); // ★
  static const lime500 = Color(0xFFA9D32F);
  static const lime900 = Color(0xFF5A8A1E);
  // Coral
  static const coral300 = Color(0xFFFFA08A);
  static const coral400 = Color(0xFFFF7A59); // ★
  static const coral500 = Color(0xFFE8705F);
  // Amber
  static const amber300 = Color(0xFFF7D580);
  static const amber400 = Color(0xFFF2C14B); // ★
  // Blue
  static const blue300 = Color(0xFF8FBAFF); // ★
  static const blue400 = Color(0xFF6EA8FF);
  // Gray · 中性
  static const gray50 = Color(0xFFF4F3EF);
  static const gray500 = Color(0xFF8B8F86);
  static const gray850 = Color(0xFF22252E);
  static const gray900 = Color(0xFF181B22);
  static const gray950 = Color(0xFF171A21);
  static const gray1000 = Color(0xFF14161C);
}

/// opacity.* — 淡色 alpha 规则(与 tokens JSON 对应)。
/// 语义色已在 CoFitColors 中预混;此处仅供 theme 层派生新淡色(如选中光晕)使用。
abstract class CoFitOpacities {
  static const subtle = 0.16; // 淡底 = 主色 @16%
  static const border = 0.40; // 淡描边 = 主色 @40%
  static const glow = 0.18; // 选中光晕 lime @18%
  static const faint = 0.09; // 更淡的底(创建横幅 lime @9%)
  static const overlay = 0.62; // 悬浮层底 gray-850 @62%
}

@immutable
class CoFitColors extends ThemeExtension<CoFitColors> {
  const CoFitColors({
    required this.primaryMain,
    required this.primaryOn,
    required this.primarySubtle,
    required this.primaryBorder,
    required this.primaryPressed,
    required this.bgApp,
    required this.bgSurface,
    required this.bgOverlay, // 需配合 BackdropFilter blur
    required this.bgDeep,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.statusActive,
    required this.statusPaused,
    required this.statusIdle,
    required this.statusDanger,
    required this.statusInfo,
    required this.typeStrength,
    required this.typeStrengthSubtle,
    required this.typeCardio,
    required this.typeCardioSubtle,
    required this.typeCore,
    required this.typeCoreSubtle,
    required this.typeFlexibility,
    required this.typeFlexibilitySubtle,
  });

  final Color primaryMain, primaryOn, primarySubtle, primaryBorder, primaryPressed;
  final Color bgApp, bgSurface, bgOverlay, bgDeep;
  final Color borderSubtle, borderStrong, borderFocus;
  final Color textPrimary, textSecondary, textTertiary, textDisabled;
  final Color statusActive, statusPaused, statusIdle, statusDanger, statusInfo;
  final Color typeStrength, typeStrengthSubtle;
  final Color typeCardio, typeCardioSubtle;
  final Color typeCore, typeCoreSubtle;
  final Color typeFlexibility, typeFlexibilitySubtle;

  /// Alpha 规则:淡底 = main @16%,描边 = main @40%,文字层级 = gray-50 @70/50/42%,分隔线 = white @7–9%
  static final dark = CoFitColors(
    primaryMain: CoFitPalette.lime400,
    primaryOn: CoFitPalette.gray950,
    primarySubtle: CoFitPalette.lime400.withValues(alpha: .16),
    primaryBorder: CoFitPalette.lime400.withValues(alpha: .40),
    primaryPressed: CoFitPalette.lime500,
    bgApp: CoFitPalette.gray900,
    bgSurface: CoFitPalette.gray850,
    bgOverlay: CoFitPalette.gray850.withValues(alpha: .62),
    bgDeep: CoFitPalette.gray1000,
    borderSubtle: Colors.white.withValues(alpha: .07),
    borderStrong: Colors.white.withValues(alpha: .09),
    borderFocus: CoFitPalette.lime400,
    textPrimary: CoFitPalette.gray50,
    textSecondary: CoFitPalette.gray50.withValues(alpha: .70),
    textTertiary: CoFitPalette.gray50.withValues(alpha: .50),
    textDisabled: CoFitPalette.gray50.withValues(alpha: .42),
    statusActive: CoFitPalette.lime400,
    statusPaused: CoFitPalette.amber400,
    statusIdle: CoFitPalette.gray500,
    statusDanger: CoFitPalette.coral500,
    statusInfo: CoFitPalette.blue400,
    typeStrength: CoFitPalette.coral400,
    typeStrengthSubtle: CoFitPalette.coral400.withValues(alpha: .16),
    typeCardio: CoFitPalette.lime400,
    typeCardioSubtle: CoFitPalette.lime400.withValues(alpha: .16),
    typeCore: CoFitPalette.amber400,
    typeCoreSubtle: CoFitPalette.amber400.withValues(alpha: .16),
    typeFlexibility: CoFitPalette.blue300,
    typeFlexibilitySubtle: CoFitPalette.blue300.withValues(alpha: .16),
  );

  @override
  CoFitColors copyWith() => this; // 单主题,暂不需要字段级 copyWith

  @override
  CoFitColors lerp(CoFitColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return CoFitColors(
      primaryMain: l(primaryMain, other.primaryMain),
      primaryOn: l(primaryOn, other.primaryOn),
      primarySubtle: l(primarySubtle, other.primarySubtle),
      primaryBorder: l(primaryBorder, other.primaryBorder),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      bgApp: l(bgApp, other.bgApp),
      bgSurface: l(bgSurface, other.bgSurface),
      bgOverlay: l(bgOverlay, other.bgOverlay),
      bgDeep: l(bgDeep, other.bgDeep),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      borderStrong: l(borderStrong, other.borderStrong),
      borderFocus: l(borderFocus, other.borderFocus),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textDisabled: l(textDisabled, other.textDisabled),
      statusActive: l(statusActive, other.statusActive),
      statusPaused: l(statusPaused, other.statusPaused),
      statusIdle: l(statusIdle, other.statusIdle),
      statusDanger: l(statusDanger, other.statusDanger),
      statusInfo: l(statusInfo, other.statusInfo),
      typeStrength: l(typeStrength, other.typeStrength),
      typeStrengthSubtle: l(typeStrengthSubtle, other.typeStrengthSubtle),
      typeCardio: l(typeCardio, other.typeCardio),
      typeCardioSubtle: l(typeCardioSubtle, other.typeCardioSubtle),
      typeCore: l(typeCore, other.typeCore),
      typeCoreSubtle: l(typeCoreSubtle, other.typeCoreSubtle),
      typeFlexibility: l(typeFlexibility, other.typeFlexibility),
      typeFlexibilitySubtle: l(typeFlexibilitySubtle, other.typeFlexibilitySubtle),
    );
  }
}

// 注册:
// MaterialApp(
//   theme: ThemeData(
//     brightness: Brightness.dark,
//     scaffoldBackgroundColor: CoFitPalette.gray900,
//     extensions: [CoFitColors.dark],
//   ),
// )
// 读取: final c = Theme.of(context).extension<CoFitColors>()!;

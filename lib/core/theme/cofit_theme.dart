import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cofit_colors.dart';
import 'cofit_dimens.dart';

/// CoFit 全局主题(深色唯一)。
/// 设计事实源:lib/core/theme/tokens/cofit.tokens.json + docs/README.md。
/// 字体:英文/数字 Space Grotesk(标题 700 / 标签 600),中文按字形自动 fallback 系统字体。
abstract class CoFitTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: CoFitPalette.lime400,
      onPrimary: CoFitPalette.gray950,
      secondary: CoFitPalette.blue300,
      onSecondary: CoFitPalette.gray950,
      surface: CoFitPalette.gray850,
      onSurface: CoFitPalette.gray50,
      error: CoFitPalette.coral500,
      onError: CoFitPalette.gray50,
      outline: CoFitPalette.gray500,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: CoFitPalette.gray900,
      extensions: const [],
    );

    final cofitColors = CoFitColors.dark;

    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme)
        .apply(
          bodyColor: cofitColors.textPrimary,
          displayColor: cofitColors.textPrimary,
        )
        .copyWith(
          // 标题 = fontWeight.heading (700)
          displayLarge: _weight(base.textTheme.displayLarge, CoFitFontWeights.heading),
          displayMedium: _weight(base.textTheme.displayMedium, CoFitFontWeights.heading),
          displaySmall: _weight(base.textTheme.displaySmall, CoFitFontWeights.heading),
          headlineLarge: _weight(base.textTheme.headlineLarge, CoFitFontWeights.heading),
          headlineMedium: _weight(base.textTheme.headlineMedium, CoFitFontWeights.heading),
          headlineSmall: _weight(base.textTheme.headlineSmall, CoFitFontWeights.heading),
          titleLarge: _weight(base.textTheme.titleLarge, CoFitFontWeights.heading),
          titleMedium: _weight(base.textTheme.titleMedium, CoFitFontWeights.heading),
          // 标签 = fontWeight.label (600)
          labelLarge: _weight(base.textTheme.labelLarge, CoFitFontWeights.label),
          labelMedium: _weight(base.textTheme.labelMedium, CoFitFontWeights.label),
          labelSmall: _weight(base.textTheme.labelSmall, CoFitFontWeights.label),
        );

    return base.copyWith(
      extensions: [cofitColors],
      textTheme: textTheme,
      dividerColor: cofitColors.borderSubtle,
      cardTheme: CardThemeData(
        color: cofitColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
          side: BorderSide(
            color: cofitColors.borderSubtle,
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cofitColors.bgSurface,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        ),
      ),
    );
  }

  static TextStyle? _weight(TextStyle? style, FontWeight weight) {
    return GoogleFonts.spaceGrotesk(textStyle: style?.copyWith(fontWeight: weight));
  }
}

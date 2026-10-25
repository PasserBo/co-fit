import 'package:flutter/material.dart';

import 'cofit_colors.dart';
import 'cofit_dimens.dart';

/// CoFit 全局主题(深色唯一)。
/// 设计事实源:lib/core/theme/tokens/cofit.tokens.json + docs/README.md。
/// 字体:英文/数字 Space Grotesk(标题 700 / 标签 600),中文按字形自动 fallback 系统字体。
/// 字体文件已打包进 assets/fonts(OFL 许可),不再运行时拉取 —— 离线首启也不掉字形。
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

    final textTheme = base.textTheme
        .apply(
          fontFamily: _fontFamily,
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
      // 统一表单/弹层/按钮外观:各 feature 不再逐处写 OutlineInputBorder 等。
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cofitColors.bgDeep,
        labelStyle: textTheme.bodySmall?.copyWith(color: cofitColors.textTertiary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: cofitColors.textDisabled),
        helperStyle: textTheme.labelSmall?.copyWith(color: cofitColors.textTertiary),
        counterStyle: textTheme.labelSmall?.copyWith(color: cofitColors.textDisabled),
        errorStyle: textTheme.labelSmall?.copyWith(color: cofitColors.statusDanger),
        border: _inputBorder(cofitColors.borderSubtle),
        enabledBorder: _inputBorder(cofitColors.borderSubtle),
        focusedBorder: _inputBorder(
          cofitColors.primaryBorder,
          width: CoFitDimens.borderWidthFocus,
        ),
        errorBorder: _inputBorder(cofitColors.statusDanger),
        focusedErrorBorder: _inputBorder(
          cofitColors.statusDanger,
          width: CoFitDimens.borderWidthFocus,
        ),
        disabledBorder: _inputBorder(
          cofitColors.borderSubtle.withValues(alpha: CoFitOpacities.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cofitColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CoFitDimens.radiusLg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cofitColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle:
            textTheme.bodySmall?.copyWith(color: cofitColors.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cofitColors.bgSurface,
        selectedColor: cofitColors.primarySubtle,
        checkmarkColor: cofitColors.primaryMain,
        labelStyle: textTheme.labelMedium?.copyWith(color: cofitColors.textPrimary),
        side: BorderSide(
          color: cofitColors.borderStrong,
          width: CoFitDimens.borderWidthHairline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(CoFitDimens.sizeMinTapTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(CoFitDimens.sizeMinTapTarget),
          foregroundColor: cofitColors.textPrimary,
          textStyle: textTheme.labelLarge,
          side: BorderSide(
            color: cofitColors.borderStrong,
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cofitColors.textSecondary,
          textStyle: textTheme.labelLarge,
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

  static OutlineInputBorder _inputBorder(
    Color color, {
    double width = CoFitDimens.borderWidthHairline,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// 打包字体的 family 名(与 pubspec.yaml 的 fonts.family 一致)。
  static const _fontFamily = 'SpaceGrotesk';

  static TextStyle? _weight(TextStyle? style, FontWeight weight) {
    return style?.copyWith(fontFamily: _fontFamily, fontWeight: weight);
  }
}

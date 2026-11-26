import 'package:flutter/material.dart';

import 'carps_colors.dart';

/// Inter is bundled for Android and web (DESIGN.md §5.1).
const carpsBodyFont = 'Inter';

TextTheme _textTheme(Color primary, Color secondary) {
  TextStyle s(double size, double height, FontWeight w, double ls, Color c) =>
      TextStyle(
        fontFamily: carpsBodyFont,
        fontSize: size,
        height: height / size,
        fontWeight: w,
        letterSpacing: ls,
        color: c,
      );
  // Sizes follow the Figma frames (14px body, 12px labels) which are one step
  // tighter than DESIGN.md §5.2.
  return TextTheme(
    displayLarge: s(40, 44, FontWeight.w700, -0.8, primary),
    headlineLarge: s(32, 38, FontWeight.w700, -0.8, primary), // titleXL
    headlineMedium: s(24, 30, FontWeight.w700, -0.4, primary), // titleL
    titleLarge: s(20, 26, FontWeight.w700, -0.2, primary), // titleM
    titleMedium: s(17, 22, FontWeight.w600, -0.2, primary), // titleS
    titleSmall: s(14, 20, FontWeight.w600, 0, primary),
    bodyLarge: s(16, 24, FontWeight.w400, -0.1, primary),
    bodyMedium: s(14, 20, FontWeight.w400, 0, primary),
    bodySmall: s(12, 16, FontWeight.w400, 0, secondary),
    labelLarge: s(16, 22, FontWeight.w700, -0.1, primary),
    labelMedium: s(14, 20, FontWeight.w500, 0, primary),
    labelSmall: s(12, 16, FontWeight.w500, 0, secondary),
  );
}

ThemeData buildCarpsTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? CarpsColors.light : CarpsColors.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accentFill,
    onPrimary: c.onAccent,
    secondary: c.selectFill,
    onSecondary: c.onSelect,
    error: c.error,
    onError: c.onError,
    surface: c.canvas,
    onSurface: c.textPrimary,
    surfaceContainerHighest: c.muted,
    onSurfaceVariant: c.textSecondary,
    outline: c.borderStrong,
    outlineVariant: c.borderSubtle,
    inverseSurface: c.inverse,
    onInverseSurface: c.onInverse,
  );
  final fieldRadius = BorderRadius.circular(12);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.page,
    fontFamily: carpsBodyFont,
    textTheme: _textTheme(c.textPrimary, c.textSecondary),
    extensions: [c],
    splashFactory: NoSplash.splashFactory,
    dividerColor: c.borderSubtle,
    // Visible focus ring for keyboard users on web (DESIGN.md §8.3).
    focusColor: c.accentFill.withValues(alpha: 0.24),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.muted,
      hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: c.accentFill, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: c.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: c.error, width: 2)),
      errorStyle: TextStyle(color: c.error, fontSize: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverse,
      contentTextStyle: TextStyle(
          color: c.onInverse, fontFamily: carpsBodyFont, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actionTextColor: c.accentOnInverse,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.canvas,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.onSelect : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.selectFill : c.borderStrong),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.selectFill : Colors.transparent),
      checkColor: WidgetStatePropertyAll(c.onSelect),
      side: BorderSide(color: c.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}

final carpsLightTheme = buildCarpsTheme(Brightness.light);
final carpsDarkTheme = buildCarpsTheme(Brightness.dark);

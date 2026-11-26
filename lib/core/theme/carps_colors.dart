import 'package:flutter/material.dart';

/// Semantic color tokens from DESIGN.md §4.2, plus `page`: the warm
/// off-white (#FBF9F8) the Figma frames use behind white cards.
@immutable
class CarpsColors extends ThemeExtension<CarpsColors> {
  const CarpsColors({
    required this.page,
    required this.canvas,
    required this.muted,
    required this.inverse,
    required this.inverseRaised,
    required this.highlight,
    required this.onHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.onInverse,
    required this.onInverseSecondary,
    required this.accentFill,
    required this.onAccent,
    required this.accentOnInverse,
    required this.accentText,
    required this.accentTint,
    required this.selectFill,
    required this.onSelect,
    required this.borderSubtle,
    required this.borderStrong,
    required this.error,
    required this.onError,
    required this.success,
  });

  final Color page;
  final Color canvas;
  final Color muted;
  final Color inverse;
  final Color inverseRaised;
  final Color highlight;
  final Color onHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color onInverse;
  final Color onInverseSecondary;
  final Color accentFill;
  final Color onAccent;
  final Color accentOnInverse;
  final Color accentText;
  final Color accentTint;
  final Color selectFill;
  final Color onSelect;
  final Color borderSubtle;
  final Color borderStrong;
  final Color error;
  final Color onError;
  final Color success;

  static const light = CarpsColors(
    page: Color(0xFFFBF9F8),
    canvas: Color(0xFFFFFFFF),
    muted: Color(0xFFF5F5F5),
    inverse: Color(0xFF0A0A0A),
    inverseRaised: Color(0xFF1F1F1F),
    highlight: Color(0xFFF5F5F5),
    onHighlight: Color(0xFF0A0A0A),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF6B6B6B),
    textDisabled: Color(0xFFB5B5B5),
    onInverse: Color(0xFFFFFFFF),
    onInverseSecondary: Color(0xFFA3A3A3),
    accentFill: Color(0xFFE8590C),
    onAccent: Color(0xFF0A0A0A),
    accentOnInverse: Color(0xFFE8590C),
    accentText: Color(0xFFB8420A),
    accentTint: Color(0xFFFFF1E8),
    selectFill: Color(0xFF0A0A0A),
    onSelect: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE5E5E5),
    borderStrong: Color(0xFF8A8A8A),
    error: Color(0xFFC4261A),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF13803D),
  );

  /// Orange on dark surfaces follows Figma (#E8590C, ~5:1 on #0A0A0A) rather
  /// than DESIGN.md's #FF6B1A.
  /// Used for the dark "sheet" island (DESIGN.md island rule 1). Full dark
  /// mode is a stretch goal and is not exposed in Settings.
  static const dark = CarpsColors(
    page: Color(0xFF0A0A0A),
    canvas: Color(0xFF0A0A0A),
    muted: Color(0xFF1F1F1F),
    inverse: Color(0xFF161616),
    inverseRaised: Color(0xFF1F1F1F),
    highlight: Color(0xFFF5F5F5),
    onHighlight: Color(0xFF0A0A0A),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFA3A3A3),
    textDisabled: Color(0xFF525252),
    onInverse: Color(0xFFF5F5F5),
    onInverseSecondary: Color(0xFFA3A3A3),
    accentFill: Color(0xFFE8590C),
    onAccent: Color(0xFF0A0A0A),
    accentOnInverse: Color(0xFFE8590C),
    accentText: Color(0xFFE8590C),
    accentTint: Color(0xFF2B1609),
    selectFill: Color(0xFFF5F5F5),
    onSelect: Color(0xFF0A0A0A),
    borderSubtle: Color(0xFF2A2A2A),
    borderStrong: Color(0xFF737373),
    error: Color(0xFFFF6B60),
    onError: Color(0xFF0A0A0A),
    success: Color(0xFF3DD47A),
  );

  @override
  CarpsColors copyWith() => this;

  @override
  CarpsColors lerp(ThemeExtension<CarpsColors>? other, double t) =>
      t < 0.5 || other is! CarpsColors ? this : other;
}

extension CarpsColorsX on BuildContext {
  CarpsColors get carps => Theme.of(this).extension<CarpsColors>()!;
}

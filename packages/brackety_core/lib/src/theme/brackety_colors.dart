import 'package:flutter/material.dart';

/// Colors that Material's [ColorScheme] does not cover: states and the mat.
class BracketyColors extends ThemeExtension<BracketyColors> {
  const BracketyColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.heri,
    required this.onHeri,
    required this.matFrame,
  });

  factory BracketyColors.from(Brightness brightness) =>
      brightness == Brightness.light ? _light : _dark;

  static const _light = BracketyColors(
    success: Color(0xFF3D6B2E),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDDE8D0),
    onSuccessContainer: Color(0xFF1E3312),
    warning: Color(0xFF8A5A00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFF6E7C2),
    onWarningContainer: Color(0xFF3D2A00),
    heri: Color(0xFF2F3B26),
    onHeri: Color(0xFFFFFFFF),
    matFrame: Color(0xFF2F3B26),
  );

  static const _dark = BracketyColors(
    success: Color(0xFF9CC46A),
    onSuccess: Color(0xFF161914),
    successContainer: Color(0xFF2F3F1E),
    onSuccessContainer: Color(0xFFDDE8C8),
    warning: Color(0xFFE0B354),
    onWarning: Color(0xFF161914),
    warningContainer: Color(0xFF4A3A12),
    onWarningContainer: Color(0xFFF6E7C2),
    heri: Color(0xFF0E110B),
    onHeri: Color(0xFFECEEE6),
    matFrame: Color(0xFF3E5326),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// The mat border (heri): headers and side bars that frame the mat.
  final Color heri;
  final Color onHeri;

  /// The border of a mat tile in the club's floor plan.
  final Color matFrame;

  static BracketyColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BracketyColors>() ??
        BracketyColors.from(theme.brightness);
  }

  @override
  BracketyColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? heri,
    Color? onHeri,
    Color? matFrame,
  }) => BracketyColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    heri: heri ?? this.heri,
    onHeri: onHeri ?? this.onHeri,
    matFrame: matFrame ?? this.matFrame,
  );

  @override
  BracketyColors lerp(BracketyColors? other, double t) {
    if (other == null) return this;
    return BracketyColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      heri: Color.lerp(heri, other.heri, t)!,
      onHeri: Color.lerp(onHeri, other.onHeri, t)!,
      matFrame: Color.lerp(matFrame, other.matFrame, t)!,
    );
  }
}

/// Colors a location can assign to each competitor (red/white, red/blue…).
/// Fixed in both light and dark mode: a red corner is red everywhere.
enum CompetitorColor {
  red(Color(0xFFC62B2B), Colors.white),
  blue(Color(0xFF1F57B8), Colors.white),
  white(Colors.white, _ink),
  black(_ink, Colors.white),
  yellow(Color(0xFFFFD600), _ink),
  green(Color(0xFF2E7D32), Colors.white),
  orange(Color(0xFFF57C00), _ink),
  purple(Color(0xFF6A1B9A), Colors.white),
  pink(Color(0xFFC2185B), Colors.white),
  sky(Color(0xFF4FC3F7), _ink),
  brown(Color(0xFF6D4C41), Colors.white),
  grey(Color(0xFF616161), Colors.white);

  const CompetitorColor(this.color, this.onColor);

  final Color color;
  final Color onColor;
}

const _ink = Color(0xFF1A1A1A);

/// WCAG contrast ratio between two colors (1 to 21; AA text needs 4.5).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

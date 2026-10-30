import 'package:flutter/material.dart';

/// Status colors that Material's [ColorScheme] does not cover.
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
  });

  factory BracketyColors.from(Brightness brightness) {
    final success = _scheme(const Color(0xFF1E8E3E), brightness);
    final warning = _scheme(const Color(0xFFF59E0B), brightness);
    return BracketyColors(
      success: success.primary,
      onSuccess: success.onPrimary,
      successContainer: success.primaryContainer,
      onSuccessContainer: success.onPrimaryContainer,
      warning: warning.primary,
      onWarning: warning.onPrimary,
      warningContainer: warning.primaryContainer,
      onWarningContainer: warning.onPrimaryContainer,
    );
  }

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  static BracketyColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BracketyColors>() ??
        BracketyColors.from(theme.brightness);
  }

  static ColorScheme _scheme(Color seed, Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      );

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
  }) => BracketyColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
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
    );
  }
}

/// Colors a location can assign to each competitor (red/white, red/blue…).
/// Fixed in both light and dark mode: a red corner is red everywhere.
enum CompetitorColor {
  red(Color(0xFFD32F2F), Colors.white),
  blue(Color(0xFF1565C0), Colors.white),
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

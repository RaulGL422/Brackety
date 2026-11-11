import 'package:flutter/material.dart';

/// Colors that Material's [ColorScheme] does not cover: states and the header band.
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
    required this.band,
    required this.onBand,
    required this.action,
    required this.onAction,
    required this.actionContainer,
    required this.onActionContainer,
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
    band: Color(0xFF1A1A1A),
    onBand: Color(0xFFFFFFFF),
    action: Color(0xFF4B2FC9),
    onAction: Color(0xFFFFFFFF),
    actionContainer: Color(0xFFECE8FB),
    onActionContainer: Color(0xFF2A1878),
  );

  static const _dark = BracketyColors(
    success: Color(0xFF9CC46A),
    onSuccess: Color(0xFF141414),
    successContainer: Color(0xFF2F3F1E),
    onSuccessContainer: Color(0xFFDDE8C8),
    warning: Color(0xFFE0B354),
    onWarning: Color(0xFF141414),
    warningContainer: Color(0xFF4A3A12),
    onWarningContainer: Color(0xFFF6E7C2),
    band: Color(0xFF000000),
    onBand: Color(0xFFEDEDED),
    action: Color(0xFFB7A8FF),
    onAction: Color(0xFF1B0F5C),
    actionContainer: Color(0xFF2E2370),
    onActionContainer: Color(0xFFE4DEFF),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// The dark band of the headers that frame a location (the referee's mat).
  final Color band;
  final Color onBand;

  /// The one colour of what can be pressed to move forward (main buttons, selected tab).
  /// Ink stays for text and frames, so an action never looks like content.
  final Color action;
  final Color onAction;
  final Color actionContainer;
  final Color onActionContainer;

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
    Color? band,
    Color? onBand,
    Color? action,
    Color? onAction,
    Color? actionContainer,
    Color? onActionContainer,
  }) => BracketyColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    band: band ?? this.band,
    onBand: onBand ?? this.onBand,
    action: action ?? this.action,
    onAction: onAction ?? this.onAction,
    actionContainer: actionContainer ?? this.actionContainer,
    onActionContainer: onActionContainer ?? this.onActionContainer,
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
      band: Color.lerp(band, other.band, t)!,
      onBand: Color.lerp(onBand, other.onBand, t)!,
      action: Color.lerp(action, other.action, t)!,
      onAction: Color.lerp(onAction, other.onAction, t)!,
      actionContainer: Color.lerp(actionContainer, other.actionContainer, t)!,
      onActionContainer: Color.lerp(
        onActionContainer,
        other.onActionContainer,
        t,
      )!,
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brackety_colors.dart';
import 'tokens.dart';

const _bodyFont = 'packages/brackety_core/ZenKakuGothicNew';
const _displayFont = 'packages/brackety_core/SairaCondensed';

/// The bundled fonts are OFL: their notices must appear in the licenses page.
void registerFontLicenses() {
  for (final (name, file) in [
    ('Zen Kaku Gothic New', 'OFL-ZenKakuGothicNew.txt'),
    ('Saira Condensed', 'OFL-SairaCondensed.txt'),
  ]) {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(
        'packages/brackety_core/assets/fonts/$file',
      );
      yield LicenseEntryWithLineBreaks([name], text);
    });
  }
}

ThemeData lightTheme() => buildTheme(Brightness.light);

ThemeData darkTheme() => buildTheme(Brightness.dark);

ThemeData buildTheme(Brightness brightness) {
  final scheme = brightness == Brightness.light ? _light : _dark;
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: _bodyFont,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.m),
  );
  const buttonSize = Size(64, AppSizes.touchTarget);
  final buttonText = base.textTheme.labelLarge!.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme),
    extensions: [BracketyColors.from(brightness)],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.onSurface, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: buttonShape,
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: BorderSide(color: scheme.outline),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: buttonShape,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: buttonShape,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// Tatami: the mat is the object of the day. Igusa green (the straw) is the
// action colour, so red and blue stay for the two corners only.
const _light = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF4A6B2A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDDE4CF),
  onPrimaryContainer: Color(0xFF22241F),
  secondary: Color(0xFF2F3B26),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE6E9DF),
  onSecondaryContainer: Color(0xFF22241F),
  tertiary: Color(0xFFD9A83A),
  onTertiary: Color(0xFF22241F),
  tertiaryContainer: Color(0xFFF6E7C2),
  onTertiaryContainer: Color(0xFF22241F),
  error: Color(0xFF8A3A12),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF6DFD3),
  onErrorContainer: Color(0xFF4A1C06),
  surface: Color(0xFFF3F4EF),
  onSurface: Color(0xFF22241F),
  onSurfaceVariant: Color(0xFF4C5245),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFEBEDE5),
  surfaceContainerHigh: Color(0xFFE4E7DD),
  surfaceContainerHighest: Color(0xFFDDE1D5),
  outline: Color(0xFF8B9180),
  outlineVariant: Color(0xFFD5D8CE),
  inverseSurface: Color(0xFF22241F),
  onInverseSurface: Color(0xFFF3F4EF),
  inversePrimary: Color(0xFF8DB25A),
  surfaceTint: Colors.transparent,
);

// Not an inverted palette: the hall with the lights down. The green gets
// lighter to stay the action colour, with dark text on it.
const _dark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF8DB25A),
  onPrimary: Color(0xFF161914),
  primaryContainer: Color(0xFF27301D),
  onPrimaryContainer: Color(0xFFDDE8C8),
  secondary: Color(0xFFC9D8AE),
  onSecondary: Color(0xFF161914),
  secondaryContainer: Color(0xFF2A3024),
  onSecondaryContainer: Color(0xFFECEEE6),
  tertiary: Color(0xFFE0B354),
  onTertiary: Color(0xFF161914),
  tertiaryContainer: Color(0xFF4A3A12),
  onTertiaryContainer: Color(0xFFF6E7C2),
  error: Color(0xFFF0A27A),
  onError: Color(0xFF2A1105),
  errorContainer: Color(0xFF5A2810),
  onErrorContainer: Color(0xFFF6DFD3),
  surface: Color(0xFF161914),
  onSurface: Color(0xFFECEEE6),
  onSurfaceVariant: Color(0xFFA7AE9B),
  surfaceContainerLowest: Color(0xFF10130E),
  surfaceContainerLow: Color(0xFF1F231B),
  surfaceContainer: Color(0xFF232820),
  surfaceContainerHigh: Color(0xFF2A2F25),
  surfaceContainerHighest: Color(0xFF333A2C),
  outline: Color(0xFF5A6150),
  outlineVariant: Color(0xFF333A2C),
  inverseSurface: Color(0xFFECEEE6),
  onInverseSurface: Color(0xFF22241F),
  inversePrimary: Color(0xFF4A6B2A),
  surfaceTint: Colors.transparent,
);

TextTheme _textTheme(TextTheme base) {
  TextStyle display(TextStyle style, FontWeight weight) =>
      style.copyWith(fontFamily: _displayFont, fontWeight: weight);

  return base.copyWith(
    displayLarge: display(base.displayLarge!, FontWeight.w800),
    displayMedium: display(base.displayMedium!, FontWeight.w800),
    displaySmall: display(base.displaySmall!, FontWeight.w800),
    headlineLarge: display(base.headlineLarge!, FontWeight.w800),
    headlineMedium: display(base.headlineMedium!, FontWeight.w700),
    headlineSmall: display(base.headlineSmall!, FontWeight.w700),
    titleLarge: base.titleLarge!.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.titleMedium!.copyWith(fontWeight: FontWeight.w700),
    titleSmall: base.titleSmall!.copyWith(fontWeight: FontWeight.w700),
  );
}

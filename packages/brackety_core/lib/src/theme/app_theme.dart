import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brackety_colors.dart';
import 'tokens.dart';

const _brandPrimary = Color(0xFF2F5BFF);
const _brandAccent = Color(0xFFFF6B00);

const _bodyFont = 'packages/brackety_core/Barlow';
const _displayFont = 'packages/brackety_core/BarlowCondensed';

/// The bundled fonts are OFL: their notice must appear in the licenses page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'packages/brackety_core/assets/fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['Barlow'], text);
  });
}

ThemeData lightTheme() => buildTheme(Brightness.light);

ThemeData darkTheme() => buildTheme(Brightness.dark);

ThemeData buildTheme(Brightness brightness) {
  final scheme = _colorScheme(brightness);
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: _bodyFont,
    useMaterial3: true,
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.m),
  );
  const buttonSize = Size(64, AppSizes.touchTarget);
  final buttonText = base.textTheme.labelLarge!.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme),
    extensions: [BracketyColors.from(brightness)],
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
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
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
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

ColorScheme _colorScheme(Brightness brightness) {
  final main = ColorScheme.fromSeed(
    seedColor: _brandPrimary,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  // The accent goes in tertiary with its own tonal palette, so it keeps its
  // hue instead of being derived from the primary.
  final accent = ColorScheme.fromSeed(
    seedColor: _brandAccent,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  return main.copyWith(
    tertiary: accent.primary,
    onTertiary: accent.onPrimary,
    tertiaryContainer: accent.primaryContainer,
    onTertiaryContainer: accent.onPrimaryContainer,
  );
}

TextTheme _textTheme(TextTheme base) {
  TextStyle display(TextStyle style, FontWeight weight) =>
      style.copyWith(fontFamily: _displayFont, fontWeight: weight);

  return base.copyWith(
    displayLarge: display(base.displayLarge!, FontWeight.w800),
    displayMedium: display(base.displayMedium!, FontWeight.w800),
    displaySmall: display(base.displaySmall!, FontWeight.w700),
    headlineLarge: display(base.headlineLarge!, FontWeight.w700),
    headlineMedium: display(base.headlineMedium!, FontWeight.w700),
    headlineSmall: display(base.headlineSmall!, FontWeight.w600),
    titleLarge: base.titleLarge!.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium!.copyWith(fontWeight: FontWeight.w600),
  );
}

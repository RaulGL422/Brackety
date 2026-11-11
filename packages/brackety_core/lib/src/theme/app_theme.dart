import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brackety_colors.dart';
import 'tokens.dart';

const _bodyFont = 'packages/brackety_core/AtkinsonHyperlegibleNext';
const _displayFont = 'packages/brackety_core/SairaCondensed';

/// The bundled fonts are OFL: their notices must appear in the licenses page.
void registerFontLicenses() {
  for (final (name, file) in [
    ('Atkinson Hyperlegible Next', 'OFL-AtkinsonHyperlegibleNext.txt'),
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
  const buttonSize = Size(64, AppSizes.buttonHeight);
  final buttonText = base.textTheme.labelLarge!.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );
  final colors = BracketyColors.from(brightness);
  final text = _textTheme(base.textTheme);
  final menuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.l),
    side: BorderSide(color: scheme.outlineVariant),
  );

  return base.copyWith(
    textTheme: text,
    extensions: [colors],
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
        backgroundColor: colors.action,
        foregroundColor: colors.onAction,
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
      // A text button is the quiet way out (Cancelar, Volver): ink and underlined, so it
      // reads as pressable without competing with the action.
      style: TextButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        foregroundColor: scheme.onSurface,
        textStyle: buttonText.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
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
    // Titles in the body font: the condensed display face is for numbers and big headers,
    // in a dialog it looked squeezed.
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      insetPadding: const EdgeInsets.all(AppSpacing.l),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      titleTextStyle: text.titleLarge!.copyWith(
        fontFamily: _bodyFont,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: scheme.onSurface,
      ),
      contentTextStyle: text.bodyLarge!.copyWith(
        height: 1.5,
        color: scheme.onSurface,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.l,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: menuShape,
      menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      textStyle: text.bodyLarge!.copyWith(color: scheme.onSurface),
      labelTextStyle: WidgetStatePropertyAll(
        text.bodyLarge!.copyWith(color: scheme.onSurface),
      ),
      position: PopupMenuPosition.under,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(menuShape),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: MenuItemButton.styleFrom(
        minimumSize: const Size(0, AppSizes.buttonHeight),
        textStyle: text.bodyLarge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: text.bodyMedium!.copyWith(color: scheme.onInverseSurface),
      waitDuration: const Duration(milliseconds: 400),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: colors.actionContainer,
      indicatorShape: buttonShape,
      labelTextStyle: WidgetStateProperty.resolveWith(
        // 13 px: four labels of a phone bar must fit in 90 px each, or the bar drops them.
        (states) => text.labelMedium!.copyWith(
          fontSize: 13,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: colors.actionContainer,
      indicatorShape: buttonShape,
      selectedLabelTextStyle: text.labelLarge!.copyWith(
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: text.labelLarge,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.action),
  );
}

// Neutral: colour belongs to the competitors, which every event picks from
// [CompetitorColor], and to the states. Ink is the action colour.
const _light = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1A1A1A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE2E2E2),
  onPrimaryContainer: Color(0xFF1A1A1A),
  secondary: Color(0xFF4A4A4A),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE4E4E4),
  onSecondaryContainer: Color(0xFF1A1A1A),
  tertiary: Color(0xFF3A3A3A),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFEBEBEB),
  onTertiaryContainer: Color(0xFF1A1A1A),
  error: Color(0xFF8A3A12),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF6DFD3),
  onErrorContainer: Color(0xFF4A1C06),
  surface: Color(0xFFF2F2F2),
  onSurface: Color(0xFF1A1A1A),
  onSurfaceVariant: Color(0xFF555555),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFEAEAEA),
  surfaceContainerHigh: Color(0xFFE4E4E4),
  surfaceContainerHighest: Color(0xFFDCDCDC),
  outline: Color(0xFF8A8A8A),
  outlineVariant: Color(0xFFD4D4D4),
  inverseSurface: Color(0xFF1A1A1A),
  onInverseSurface: Color(0xFFF2F2F2),
  inversePrimary: Color(0xFFEDEDED),
  surfaceTint: Colors.transparent,
);

const _dark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFEDEDED),
  onPrimary: Color(0xFF141414),
  primaryContainer: Color(0xFF333333),
  onPrimaryContainer: Color(0xFFEDEDED),
  secondary: Color(0xFFC8C8C8),
  onSecondary: Color(0xFF141414),
  secondaryContainer: Color(0xFF2E2E2E),
  onSecondaryContainer: Color(0xFFEDEDED),
  tertiary: Color(0xFFC8C8C8),
  onTertiary: Color(0xFF141414),
  tertiaryContainer: Color(0xFF2A2A2A),
  onTertiaryContainer: Color(0xFFEDEDED),
  error: Color(0xFFF0A27A),
  onError: Color(0xFF2A1105),
  errorContainer: Color(0xFF5A2810),
  onErrorContainer: Color(0xFFF6DFD3),
  surface: Color(0xFF141414),
  onSurface: Color(0xFFEDEDED),
  onSurfaceVariant: Color(0xFFA8A8A8),
  surfaceContainerLowest: Color(0xFF0E0E0E),
  surfaceContainerLow: Color(0xFF1F1F1F),
  surfaceContainer: Color(0xFF232323),
  surfaceContainerHigh: Color(0xFF2A2A2A),
  surfaceContainerHighest: Color(0xFF353535),
  outline: Color(0xFF6B6B6B),
  outlineVariant: Color(0xFF353535),
  inverseSurface: Color(0xFFEDEDED),
  onInverseSurface: Color(0xFF1A1A1A),
  inversePrimary: Color(0xFF1A1A1A),
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
    titleMedium: base.titleMedium!.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: base.titleSmall!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
    // One step bigger than Material: read at arm's length, standing, in a sports hall.
    bodyLarge: base.bodyLarge!.copyWith(fontSize: 17),
    bodyMedium: base.bodyMedium!.copyWith(fontSize: 16),
    bodySmall: base.bodySmall!.copyWith(fontSize: 14),
    labelLarge: base.labelLarge!.copyWith(fontSize: 16),
    labelMedium: base.labelMedium!.copyWith(fontSize: 14),
    labelSmall: base.labelSmall!.copyWith(fontSize: 13),
  );
}

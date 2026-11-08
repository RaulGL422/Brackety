import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const aa = 4.5;

  for (final brightness in Brightness.values) {
    group('$brightness theme', () {
      final theme = buildTheme(brightness);
      final c = theme.colorScheme;
      final b = theme.extension<BracketyColors>()!;

      final pairs = {
        'primary': (c.primary, c.onPrimary),
        'primaryContainer': (c.primaryContainer, c.onPrimaryContainer),
        'secondary': (c.secondary, c.onSecondary),
        'secondaryContainer': (c.secondaryContainer, c.onSecondaryContainer),
        'tertiary': (c.tertiary, c.onTertiary),
        'tertiaryContainer': (c.tertiaryContainer, c.onTertiaryContainer),
        'error': (c.error, c.onError),
        'errorContainer': (c.errorContainer, c.onErrorContainer),
        'surface': (c.surface, c.onSurface),
        'surfaceVariant': (c.surface, c.onSurfaceVariant),
        'card': (c.surfaceContainerLow, c.onSurface),
        'inputFill': (c.surfaceContainerHighest, c.onSurface),
        'snackBar': (c.inverseSurface, c.onInverseSurface),
        'success': (b.success, b.onSuccess),
        'successContainer': (b.successContainer, b.onSuccessContainer),
        'warning': (b.warning, b.onWarning),
        'warningContainer': (b.warningContainer, b.onWarningContainer),
        'heri': (b.heri, b.onHeri),
      };

      for (final MapEntry(key: name, value: (bg, fg)) in pairs.entries) {
        test('$name text meets AA contrast', () {
          expect(contrastRatio(bg, fg), greaterThanOrEqualTo(aa));
        });
      }

      // The scoreboard clock turns this colour in its last seconds: large text, 3:1.
      test('warning text on the surface meets AA for large text', () {
        expect(contrastRatio(c.surface, b.warning), greaterThanOrEqualTo(3));
      });

      test('buttons keep the minimum touch target', () {
        final size = theme.filledButtonTheme.style!.minimumSize!.resolve({});
        expect(size!.height, AppSizes.touchTarget);
      });
    });
  }

  for (final color in CompetitorColor.values) {
    test('competitor ${color.name} text meets AA contrast', () {
      expect(
        contrastRatio(color.color, color.onColor),
        greaterThanOrEqualTo(aa),
      );
    });
  }

  test('contrast ratio goes from 1 to 21', () {
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.01));
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
  });
}

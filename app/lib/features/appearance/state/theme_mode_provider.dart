import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/theme_store.dart';

final themeStoreProvider = Provider<ThemeStore>(
  (ref) => const SecureThemeStore(),
);

/// What [ThemeStore] held at start-up, read in `main` so the first frame is already right.
final savedThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// System follows the device; light or dark fixes it on this device only.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(savedThemeModeProvider);

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(themeStoreProvider).write(mode);
  }
}

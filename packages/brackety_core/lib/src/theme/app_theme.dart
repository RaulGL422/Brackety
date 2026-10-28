import 'package:flutter/material.dart';

// Placeholder until the design exploration in docs/07-diseno.md fixes the real tokens.
const _seed = Color(0xFF1F5FAD);

ThemeData lightTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  useMaterial3: true,
);

ThemeData darkTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
);

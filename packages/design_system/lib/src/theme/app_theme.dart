import 'package:flutter/material.dart';

const _seedColor = Colors.indigo;

/// Light theme — used together with [buildAppDarkTheme] and
/// `themeMode: ThemeMode.system` so the app follows the OS setting.
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

/// Dark theme counterpart of [buildAppTheme], derived from the same seed.
ThemeData buildAppDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

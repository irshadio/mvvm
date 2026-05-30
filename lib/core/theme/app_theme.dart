import 'package:flutter/material.dart';
import 'package:mvvm/core/theme/app_spacing.dart';

/// The app's single theme definition.
///
/// `app.dart` reads [AppTheme.light] for `MaterialApp.theme`, so all visual
/// configuration lives here instead of inline at the composition root. Like
/// [AppSpacing], this is compile-time design config — a plain
/// `abstract final` class, not a runtime-swappable contract (CLAUDE.md §5 is
/// for infrastructure).
///
/// Component themes are set ONLY where they consume a token defined in
/// `app_spacing.dart`; everything else inherits Material 3's defaults from the
/// generated [ColorScheme]. The base builder [_themeFrom] takes a
/// [ColorScheme], so a dark theme is a one-getter addition when needed:
/// `static ThemeData get dark => _themeFrom(ColorScheme.fromSeed(seedColor:
/// _seed, brightness: Brightness.dark));`.
abstract final class AppTheme {
  /// Seed colour the Material 3 palette is derived from.
  static const Color _seed = Colors.indigo;

  /// The light theme used by `MaterialApp.theme`.
  static ThemeData get light =>
      _themeFrom(ColorScheme.fromSeed(seedColor: _seed));

  /// Builds a [ThemeData] from [scheme], applying the shared spacing/radius
  /// tokens to component shapes. The single place visual structure is assembled
  /// for any brightness.
  static ThemeData _themeFrom(ColorScheme scheme) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    final buttonStyle = ButtonStyle(
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
    );
  }
}

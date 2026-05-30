/// Design tokens for spacing and corner radii.
///
/// The single source of truth for the numeric scale the UI is built on. Views
/// and the `AppTheme` component themes reference these instead of scattering
/// magic numbers, so the rhythm of the app can be tuned in one place.
///
/// These are compile-time constants, not a runtime-swappable dependency, so
/// they live in a plain `abstract final` class (no provider / override — that
/// pattern is for infrastructure contracts, see CLAUDE.md §5).
abstract final class AppSpacing {
  /// 4 — hairline gaps, icon-to-label padding.
  static const double xs = 4;

  /// 8 — tight gaps between related elements.
  static const double sm = 8;

  /// 12 — default gap inside a component.
  static const double md = 12;

  /// 16 — standard screen / list padding.
  static const double lg = 16;

  /// 24 — section separation, dialog insets.
  static const double xl = 24;

  /// 32 — generous separation between major blocks.
  static const double xxl = 32;
}

/// Corner-radius tokens, consumed by `AppTheme`'s component shapes.
abstract final class AppRadius {
  /// 8 — inputs, chips, small surfaces.
  static const double sm = 8;

  /// 12 — buttons, cards.
  static const double md = 12;

  /// 16 — sheets, large surfaces.
  static const double lg = 16;
}

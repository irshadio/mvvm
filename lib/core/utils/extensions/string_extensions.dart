/// Small, dependency-free string helpers used across features.
extension StringX on String {
  /// `'hello' -> 'Hello'`. Empty strings are returned unchanged.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// True when the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// True when the string has non-whitespace content.
  bool get isNotBlank => trim().isNotEmpty;
}

/// Null-aware string helpers.
extension NullableStringX on String? {
  /// True when null, empty, or only whitespace.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}

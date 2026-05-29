import 'package:flutter/material.dart';

/// Utility methods Views reach for constantly, as extensions on [BuildContext].
///
/// This is how "Views extend utility methods" in this architecture — extensions
/// (not a `BaseView` superclass), because a Widget can only extend one class.
extension BuildContextX on BuildContext {
  // --- Theme shortcuts ---
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // --- Media query shortcuts ---
  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  // --- Feedback ---
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : null,
        ),
      );
  }

  // --- Navigation (Navigator 1.0, named routes) ---
  Future<T?> pushNamed<T>(String route, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(route, arguments: arguments);

  Future<T?> pushReplacementNamed<T, R>(String route, {Object? arguments}) =>
      Navigator.of(
        this,
      ).pushReplacementNamed<T, R>(route, arguments: arguments);

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);
}

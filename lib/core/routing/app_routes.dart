import 'package:flutter/widgets.dart';

/// Centralised route names for Navigator 1.0 (used by `RouteGenerator` via
/// `onGenerateRoute`). Features reference these constants — never hard-coded
/// strings — so renames are single-edit and discoverable.
abstract final class Routes {
  /// Initial route — the splash view.
  static const String splash = '/';

  /// Home — the example posts list.
  static const String home = '/home';

  /// Post detail. Pass a `Post` as the route `arguments`.
  static const String postDetail = '/post-detail';
}

/// Global navigator key for navigation from non-widget code (e.g. the
/// `UnauthorizedHandler` redirecting to login). Attached to `MaterialApp`.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

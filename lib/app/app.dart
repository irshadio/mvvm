import 'package:flutter/material.dart';
import 'package:mvvm/app/route_generator.dart';
import 'package:mvvm/core/presentation/widgets/connectivity_banner.dart';
import 'package:mvvm/core/routing/app_routes.dart';
import 'package:mvvm/core/theme/app_theme.dart';

/// Root application widget: Navigator 1.0 driven by a central route generator,
/// starting at the splash route.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MVVM',
      navigatorKey: rootNavigatorKey,
      onGenerateRoute: onGenerateRoute,
      initialRoute: Routes.splash,
      theme: AppTheme.light,
      // Overlay the global offline banner above every route.
      builder: (context, child) => Stack(
        children: <Widget>[
          ?child,
          const Align(
            alignment: Alignment.bottomCenter,
            child: ConnectivityBanner(),
          ),
        ],
      ),
    );
  }
}

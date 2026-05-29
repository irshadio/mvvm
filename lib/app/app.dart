import 'package:flutter/material.dart';
import 'package:mvvm/app/route_generator.dart';
import 'package:mvvm/core/routing/app_routes.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/app/app.dart';
import 'package:mvvm/core/bootstrap/bootstrap.dart';
import 'package:mvvm/features/posts/posts_overrides.dart';

/// Composition root. Builds the core contract overrides (which opens async
/// infrastructure such as the database), aggregates each feature's overrides,
/// and starts the app inside a single [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final overrides = [
    ...await buildCoreOverrides(),
    ...postsOverrides,
  ];

  runApp(ProviderScope(overrides: overrides, child: const App()));
}

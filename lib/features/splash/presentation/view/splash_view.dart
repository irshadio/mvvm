import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
import 'package:mvvm/core/presentation/view_ready_mixin.dart';
import 'package:mvvm/core/routing/app_routes.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/splash/presentation/view_model/splash_view_model.dart';

/// The initial route. Shows branding while [SplashViewModel] resolves the first
/// destination, then replaces itself with that route.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with ViewReadyMixin<SplashView> {
  @override
  void onReady() => ref.read(splashViewModelProvider.notifier).resolve();

  @override
  Widget build(BuildContext context) {
    ref.listen<ViewState<String>>(splashViewModelProvider, (previous, next) {
      final destination = switch (next) {
        ViewData<String>(:final value) => value,
        ViewError<String>() => Routes.home, // fail-open to home
        _ => null,
      };
      if (destination != null) {
        unawaited(context.pushReplacementNamed<void, void>(destination));
      }
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlutterLogo(size: 96),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

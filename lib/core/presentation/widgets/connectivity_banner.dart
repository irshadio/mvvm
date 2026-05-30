import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/network/connectivity.dart';

/// A slim banner pinned to the bottom of the app while the device has no real
/// internet reachability.
///
/// Watches [connectivityStatusProvider] (the polled DNS-probe stream) and shows
/// nothing while connected — or while the status is still loading / errored
/// (treated as "assume online"). Mounted once, app-wide, via
/// `MaterialApp.builder` (see `app.dart`); this is the global ambient
/// indicator, while per-request failures still flow through
/// `Failure.noConnection -> ViewState.noInternet`.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue.value is null while loading / on error — treat as "online".
    final isOnline = ref.watch(connectivityStatusProvider).value ?? true;
    if (isOnline) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: ColoredBox(
          color: colors.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.wifi_off, size: 16, color: colors.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  'No internet connection',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

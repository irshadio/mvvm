import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/routing/app_routes.dart';
import 'package:mvvm/core/state/remote_state_mixin.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_view_model.g.dart';

/// Decides the first route after the splash screen.
///
/// A "decision" ViewModel: it follows the same shape as a data ViewModel
/// (`@riverpod` + [RemoteStateMixin]), with the resolved route name as its
/// `data`. The View watches the state and performs the navigation.
@riverpod
class SplashViewModel extends _$SplashViewModel with RemoteStateMixin<String> {
  @override
  ViewState<String> build() => const ViewState.idle();

  /// Runs the start-up routing decision.
  Future<void> resolve() => runRequest(_decideDestination);

  Future<Either<Failure, String>> _decideDestination() async {
    // Small minimum duration so the splash does not visibly flash.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // TEMPLATE: when an auth feature exists, read the session here and return
    // the login route when there is no valid token, e.g.:
    //   final token = await ref.read(secureStoreProvider).readAccessToken();
    //   if (token == null || token.isEmpty) return right(Routes.login);
    return right<Failure, String>(Routes.home);
  }
}

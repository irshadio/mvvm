import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mix into a `ConsumerState` to run one-time setup after the first frame.
///
/// This is the safe place to trigger a ViewModel's initial load: calling a
/// notifier method during `build`/`initState` directly would throw
/// ("modified a provider while the widget tree was building"). The post-frame
/// callback sidesteps that.
///
/// ```dart
/// class _PostsViewState extends ConsumerState<PostsView>
///     with ViewReadyMixin<PostsView> {
///   @override
///   void onReady() => ref.read(postsVmProvider.notifier).load();
///   ...
/// }
/// ```
mixin ViewReadyMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Called once, after the first frame, while still mounted.
  void onReady();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onReady();
    });
  }
}

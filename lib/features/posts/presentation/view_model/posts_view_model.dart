import 'package:mvvm/core/state/remote_state_mixin.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'posts_view_model.g.dart';

/// ViewModel for the posts list.
///
/// Canonical shape: a code-generated `@riverpod` Notifier whose state is a
/// `ViewState<T>`, with [RemoteStateMixin] supplying the api -> data -> state
/// machine. `load()` is a one-liner; the mixin handles loading/error/offline.
@riverpod
class PostsViewModel extends _$PostsViewModel
    with RemoteStateMixin<List<Post>> {
  @override
  ViewState<List<Post>> build() => const ViewState.idle();

  /// Loads (or reloads) the posts. Drives state via [RemoteStateMixin].
  Future<void> load() =>
      runRequest(() => ref.read(postRepositoryProvider).getPosts());
}

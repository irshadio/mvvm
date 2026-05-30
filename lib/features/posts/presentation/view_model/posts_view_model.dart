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
///
/// Pagination rides on the SAME spine: [loadMore] reuses `runRequest`, mapping
/// the next page onto the current list. A page-sized result means more may
/// remain ([hasMore]); a short page means the end.
@riverpod
class PostsViewModel extends _$PostsViewModel
    with RemoteStateMixin<List<Post>> {
  static const int _pageSize = 20;
  int _page = 1;
  bool _hasMore = true;

  /// Whether another page may exist — the View uses it to gate the footer
  /// loader and the load-more trigger.
  bool get hasMore => _hasMore;

  @override
  ViewState<List<Post>> build() => const ViewState.idle();

  /// Loads (or reloads) the first page, resetting pagination.
  Future<void> load() {
    _page = 1;
    _hasMore = true;
    return runRequest(() async {
      final result = await ref
          .read(postRepositoryProvider)
          .getPosts(page: 1, limit: _pageSize);
      return result.map((posts) {
        _hasMore = posts.length == _pageSize;
        return posts;
      });
    });
  }

  /// Appends the next page (infinite scroll). No-op while a request is in
  /// flight or once the last page has been reached.
  Future<void> loadMore() {
    if (state.isLoading || !_hasMore) return Future<void>.value();
    final current = state.dataOrNull ?? const <Post>[];
    final next = _page + 1;
    return runRequest(() async {
      final result = await ref
          .read(postRepositoryProvider)
          .getPosts(page: next, limit: _pageSize);
      return result.map((posts) {
        _hasMore = posts.length == _pageSize;
        if (posts.isNotEmpty) _page = next;
        return <Post>[...current, ...posts];
      });
    });
  }
}

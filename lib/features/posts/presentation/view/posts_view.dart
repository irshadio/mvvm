import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
import 'package:mvvm/core/presentation/extensions/ref_extensions.dart';
import 'package:mvvm/core/presentation/view_ready_mixin.dart';
import 'package:mvvm/core/presentation/view_state_switcher.dart';
import 'package:mvvm/core/routing/app_routes.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/presentation/view_model/posts_view_model.dart';

/// Posts list. A `ConsumerStatefulWidget` so it can trigger the initial load
/// after the first frame via [ViewReadyMixin]; renders state via
/// [ViewStateSwitcher].
class PostsView extends ConsumerStatefulWidget {
  const PostsView({super.key});

  @override
  ConsumerState<PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends ConsumerState<PostsView>
    with ViewReadyMixin<PostsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super
        .initState(); // ViewReadyMixin schedules onReady after the first frame.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void onReady() => ref.read(postsViewModelProvider.notifier).load();

  /// Appends the next page when the user nears the bottom. `loadMore` itself
  /// no-ops while a request is in flight or once the last page is reached.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(ref.read(postsViewModelProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh failures keep the list on screen; surface them as a toast.
    ref.listenRefreshFailures(postsViewModelProvider, context);
    final state = ref.watch(postsViewModelProvider);
    final hasMore = ref.read(postsViewModelProvider.notifier).hasMore;
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.pushNamed<Post>(Routes.createPost);
          // Reload so the list reflects the new post. NOTE: JSONPlaceholder
          // fakes POST (returns id 101 but does not persist), so the reloaded
          // list will not actually contain it — a real backend would.
          if (created != null) {
            await ref.read(postsViewModelProvider.notifier).load();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: ViewStateSwitcher<List<Post>>(
        state: state,
        onRetry: () => ref.read(postsViewModelProvider.notifier).load(),
        onData: (posts) => RefreshIndicator(
          onRefresh: ref.read(postsViewModelProvider.notifier).load,
          child: ListView.separated(
            controller: _scrollController,
            // One extra row: the infinite-scroll footer (spinner / end).
            itemCount: posts.length + 1,
            separatorBuilder: (_, index) => index < posts.length - 1
                ? const Divider(height: 1)
                : const SizedBox.shrink(),
            itemBuilder: (context, index) {
              if (index >= posts.length) {
                return _PaginationFooter(
                  isLoadingMore: state.isLoading,
                  hasMore: hasMore,
                );
              }
              final post = posts[index];
              return ListTile(
                title: Text(post.title),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    context.pushNamed<void>(Routes.postDetail, arguments: post),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Footer row for the paginated list: a spinner while the next page loads, a
/// subtle end-marker once every page is in.
class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.isLoadingMore, required this.hasMore});

  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text('No more posts', style: context.textTheme.bodySmall),
      ),
    );
  }
}

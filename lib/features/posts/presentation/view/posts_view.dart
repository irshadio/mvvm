import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
import 'package:mvvm/core/presentation/extensions/ref_extensions.dart';
import 'package:mvvm/core/presentation/view_ready_mixin.dart';
import 'package:mvvm/core/presentation/view_state_switcher.dart';
import 'package:mvvm/core/routing/app_routes.dart';
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
  @override
  void onReady() => ref.read(postsViewModelProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    // Refresh failures keep the list on screen; surface them as a toast.
    ref.listenRefreshFailures(postsViewModelProvider, context);
    final state = ref.watch(postsViewModelProvider);
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
            itemCount: posts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
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

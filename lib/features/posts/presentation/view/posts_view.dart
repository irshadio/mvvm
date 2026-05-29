import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
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
    final state = ref.watch(postsViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
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

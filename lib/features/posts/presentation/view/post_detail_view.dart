import 'package:flutter/material.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';

/// Read-only detail for a [Post]. Receives the post via route arguments
/// (see `RouteGenerator`), keeping it decoupled from data loading.
class PostDetailView extends StatelessWidget {
  const PostDetailView({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(post.title, style: context.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(post.body, style: context.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvvm/core/presentation/extensions/context_extensions.dart';
import 'package:mvvm/core/presentation/extensions/ref_extensions.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/presentation/view_model/create_post_view_model.dart';

/// Create-post form — the reference *mutation* View, the write-side counterpart
/// to `PostsView`.
///
/// The form fields live HERE (a `Form` + `TextEditingController`s with
/// validators); the ViewModel owns only the submission lifecycle
/// (`SubmissionState`). `listenSubmission` reacts once to the outcome — on
/// success it pops, returning the created [Post] to the list.
class CreatePostView extends ConsumerStatefulWidget {
  const CreatePostView({super.key});

  @override
  ConsumerState<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends ConsumerState<CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(
      ref
          .read(createPostViewModelProvider.notifier)
          .submit(
            CreatePostInput(
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // React once to the submission outcome (failure falls back to a snackbar).
    ref.listenSubmission<Post>(
      createPostViewModelProvider,
      context,
      onSuccess: (post) {
        context
          ..showSnackBar('Post "${post.title}" created')
          ..pop<Post>(post);
      },
    );
    final isSubmitting = ref.watch(createPostViewModelProvider).isInProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('New post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                enabled: !isSubmitting,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Body is required'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

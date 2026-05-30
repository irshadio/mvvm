import 'package:mvvm/core/state/mutation_state_mixin.dart';
import 'package:mvvm/core/state/submission_state.dart';
import 'package:mvvm/features/posts/domain/entities/create_post_input.dart';
import 'package:mvvm/features/posts/domain/entities/post.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_post_view_model.g.dart';

/// ViewModel for the create-post form — the canonical *mutation* example
/// (CLAUDE.md §4b).
///
/// Mirrors the read-side shape exactly, but on the write spine: a
/// code-generated `@riverpod` Notifier whose state is `SubmissionState<T>`,
/// with [MutationStateMixin] supplying the api -> submission -> state machine.
/// `submit()` is a one-liner; the mixin handles inProgress/success/failure.
@riverpod
class CreatePostViewModel extends _$CreatePostViewModel
    with MutationStateMixin<Post> {
  @override
  SubmissionState<Post> build() => const SubmissionState.idle();

  /// Submits the new post. Drives state via [MutationStateMixin].
  Future<void> submit(CreatePostInput input) =>
      runMutation(() => ref.read(postRepositoryProvider).createPost(input));
}

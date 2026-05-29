import 'package:mvvm/core/network/remote_client_provider.dart';
import 'package:mvvm/core/storage/local_store.dart';
import 'package:mvvm/features/posts/data/repositories/post_repository_impl.dart';
import 'package:mvvm/features/posts/data/sources/post_local_data_source.dart';
import 'package:mvvm/features/posts/data/sources/post_remote_data_source.dart';
import 'package:mvvm/features/posts/domain/repositories/post_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Composition-root overrides for the posts feature — binds each abstract
/// contract to its concrete implementation. Aggregated in `main()` alongside
/// the core overrides (see core/bootstrap.buildCoreOverrides).
///
/// Keeping the feature's wiring here (not in core) preserves feature
/// modularity: core knows nothing about posts.
final List<Override> postsOverrides = <Override>[
  postRemoteDataSourceProvider.overrideWith(
    (ref) => PostRemoteDataSourceImpl(ref.watch(remoteClientProvider)),
  ),
  postLocalDataSourceProvider.overrideWith(
    (ref) => PostLocalDataSourceImpl(ref.watch(localStoreProvider)),
  ),
  postRepositoryProvider.overrideWith(
    (ref) => PostRepositoryImpl(
      remote: ref.watch(postRemoteDataSourceProvider),
      local: ref.watch(postLocalDataSourceProvider),
    ),
  ),
];

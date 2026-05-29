# Feature integration templates

Copy-paste shapes for a new feature's **integration layer** (everything except
`presentation/view/**`, which the developer owns). Replace `__Feature__`
(PascalCase, e.g. `Profile`), `__feature__` (snake_case, e.g. `profile`), and
field names. The canonical, working example is `lib/features/posts/`. Keep every
file ≤ 200 lines. Obey `CLAUDE.md`.

File layout:
```
lib/features/__feature__/
  domain/entities/__feature__.dart
  domain/repositories/__feature___repository.dart
  data/dtos/__feature___dto.dart
  data/sources/__feature___remote_data_source.dart
  data/sources/__feature___local_data_source.dart      (only if caching)
  data/repositories/__feature___repository_impl.dart
  presentation/view_model/__feature___view_model.dart
  __feature___overrides.dart
```

## 1. Entity — `domain/entities/__feature__.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '__feature__.freezed.dart';

@freezed
abstract class __Feature__ with _$__Feature__ {
  const factory __Feature__({required int id, required String name}) =
      _$Feature$;
}
```

## 2. Repository contract — `domain/repositories/__feature___repository.dart`
```dart
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/__feature__/domain/entities/__feature__.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '__feature___repository.g.dart';

abstract interface class __Feature__Repository {
  Future<Either<Failure, List<__Feature__>>> getAll();
}

@riverpod
__Feature__Repository __feature__Repository(Ref ref) => throw UnimplementedError(
  '__feature__RepositoryProvider must be overridden — see __feature___overrides.dart.',
);
```

## 3. DTO + mapper — `data/dtos/__feature___dto.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvvm/features/__feature__/domain/entities/__feature__.dart';

part '__feature___dto.freezed.dart';
part '__feature___dto.g.dart';

@freezed
abstract class __Feature__Dto with _$__Feature__Dto {
  const factory __Feature__Dto({required int id, required String name}) =
      _$Feature$Dto;
  factory __Feature__Dto.fromJson(Map<String, dynamic> json) =>
      _$__Feature__DtoFromJson(json);
}

extension __Feature__DtoMapper on __Feature__Dto {
  __Feature__ toEntity() => __Feature__(id: id, name: name);
}
```

## 4. Remote data source — `data/sources/__feature___remote_data_source.dart`
```dart
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/core/error/failure_mapper.dart';
import 'package:mvvm/features/__feature__/data/dtos/__feature___dto.dart';
import 'package:remote_client/remote_client.dart' as rc;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '__feature___remote_data_source.g.dart';

abstract interface class __Feature__RemoteDataSource {
  Future<Either<Failure, List<__Feature__Dto>>> fetchAll();
}

class __Feature__RemoteDataSourceImpl implements __Feature__RemoteDataSource {
  __Feature__RemoteDataSourceImpl(this._client);
  final rc.RemoteClient _client;

  @override
  Future<Either<Failure, List<__Feature__Dto>>> fetchAll() async {
    final result = await _client.get<List<__Feature__Dto>>(
      '/__feature__s',
      fromJson: (json) => (json! as List<dynamic>)
          .map((e) => __Feature__Dto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return result.fold<Either<Failure, List<__Feature__Dto>>>(
      (failure) => left(mapRemoteFailure(failure)),
      (response) => right(response.data ?? <__Feature__Dto>[]),
    );
  }
}

@riverpod
__Feature__RemoteDataSource __feature__RemoteDataSource(Ref ref) =>
    throw UnimplementedError('Override in __feature___overrides.dart.');
```

## 5. Repository impl — `data/repositories/__feature___repository_impl.dart`
```dart
import 'package:fpdart/fpdart.dart';
import 'package:mvvm/core/error/failure.dart';
import 'package:mvvm/features/__feature__/data/dtos/__feature___dto.dart';
import 'package:mvvm/features/__feature__/data/sources/__feature___remote_data_source.dart';
import 'package:mvvm/features/__feature__/domain/entities/__feature__.dart';
import 'package:mvvm/features/__feature__/domain/repositories/__feature___repository.dart';

class __Feature__RepositoryImpl implements __Feature__Repository {
  __Feature__RepositoryImpl({required this.remote});
  final __Feature__RemoteDataSource remote;

  @override
  Future<Either<Failure, List<__Feature__>>> getAll() async {
    final result = await remote.fetchAll();
    return result.map((dtos) => dtos.map((d) => d.toEntity()).toList());
  }
}
```

## 6. ViewModel — `presentation/view_model/__feature___view_model.dart`
```dart
import 'package:mvvm/core/state/remote_state_mixin.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/__feature__/domain/entities/__feature__.dart';
import 'package:mvvm/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '__feature___view_model.g.dart';

@riverpod
class __Feature__ViewModel extends _$__Feature__ViewModel
    with RemoteStateMixin<List<__Feature__>> {
  @override
  ViewState<List<__Feature__>> build() => const ViewState.idle();

  Future<void> load() =>
      runRequest(() => ref.read(__feature__RepositoryProvider).getAll());
}
```

## 7. Overrides — `__feature___overrides.dart`
```dart
import 'package:mvvm/core/network/remote_client_provider.dart';
import 'package:mvvm/features/__feature__/data/repositories/__feature___repository_impl.dart';
import 'package:mvvm/features/__feature__/data/sources/__feature___remote_data_source.dart';
import 'package:mvvm/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final List<Override> __feature__Overrides = <Override>[
  __feature__RemoteDataSourceProvider.overrideWith(
    (ref) => __Feature__RemoteDataSourceImpl(ref.watch(remoteClientProvider)),
  ),
  __feature__RepositoryProvider.overrideWith(
    (ref) => __Feature__RepositoryImpl(
      remote: ref.watch(__feature__RemoteDataSourceProvider),
    ),
  ),
];
```

## 8. Wiring (edit existing files)
- `lib/core/routing/app_routes.dart`: add `static const String __feature__ = '/__feature__';`.
- `lib/app/route_generator.dart`: add a `case Routes.__feature__:` returning the developer's View.
- `lib/main.dart`: add `...__feature__Overrides` to the `overrides` list.

## 9. The View (developer-owned — do NOT create)
The View is a `ConsumerStatefulWidget` with `ViewReadyMixin`, watching
`__feature__ViewModelProvider` through `ViewStateSwitcher`. The agent wires the
ViewModel above; the developer builds the widget. See `posts_view.dart`.

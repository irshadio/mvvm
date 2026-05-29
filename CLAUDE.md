# CLAUDE.md — Architecture rules for agents

This repository is a **dogmatic, agent-first MVVM architecture for Flutter**. It
exists so that an automated agent (Claude Code / Opus) can add features by
following ONE fixed set of patterns. **The architecture is the agent's
responsibility, not the human reviewer's.** Do not invent alternative patterns,
do not reach for a different state-management or DI approach, and do not
"improve" the structure. Copy the existing shapes exactly.

If a rule here ever conflicts with what you remember about a library, **this file
and the existing code win** — they were verified against the installed versions.

---

## 0. Golden rules (read first)

1. **Run codegen before anything else.** `dart run build_runner build`. Missing
   `*.g.dart` / `*.freezed.dart` files are EXPECTED before codegen — they are
   git-ignored, not errors. Re-run after editing any annotated file.
2. **One ViewModel pattern only** (§4). One state type only: `ViewState<T>` (§3).
3. **Every contract is an `abstract interface class` + an `Impl`**, wired by a
   `ProviderScope` override at startup — never `new`-ed directly (§5).
4. **Pattern-match with Dart 3 `switch`, never `.when`/`.map`.** Freezed 3 made
   those legacy; they are banned here.
5. **`remote_client` types (`rc.*`) never leave `data/`.** The repository/data
   source maps them to the app's `Either<Failure, T>` (§6).
6. **Respect import boundaries** (§2). `dart run tool/check_boundaries.dart`.
7. **`flutter analyze` must be clean** (very_good_analysis) and
   **`check_boundaries` must pass** before every commit (§9).
8. **When in doubt, copy `lib/features/posts/`** — it is the reference feature.

---

## 1. Commands

```bash
dart run build_runner build      # generate code (RUN FIRST, and after edits)
dart run build_runner watch      # or keep it running while developing
flutter analyze                  # must be clean (very_good_analysis)
dart run tool/check_boundaries.dart   # import boundaries — must pass
dart format .                    # 80-col, house style
flutter test                     # unit/widget tests
```

`.env` is required for `envied` codegen; it is committed (its value is a public
URL, not a secret). For real secrets see §8.

---

## 2. Layers & import boundaries

```
lib/
  main.dart            Composition root: builds overrides, runs ProviderScope.
  app/                 Top layer. MAY import anything (core + features).
    app.dart           MaterialApp (Navigator 1.0, onGenerateRoute).
    route_generator.dart   Maps route names -> feature views.
  core/                Generic infrastructure. MUST NOT import app/ or features/.
    bootstrap/         buildCoreOverrides(): the composition root for core.
    config/            envied AppConfig.
    error/             Failure union + failure_mapper (rc.Failure -> Failure).
    network/           remote_client provider, token/unauthorized, connectivity.
    routing/           Route name constants + rootNavigatorKey.
    state/             ViewState<T>, RemoteStateMixin.
    storage/           SecureStore (tokens), LocalStore (sembast).
    presentation/      ViewStateSwitcher, default state views, extensions.
    utils/             pure helpers/extensions.
  features/<name>/     One feature. MUST NOT import another feature, or app/.
    data/              DTOs, data sources (abstract+Impl), repository Impl.
    domain/            entities, repository CONTRACT (abstract). No data/ or
                       presentation/ imports.
    presentation/      view/ (widgets) + view_model/ (@riverpod Notifiers).
    <name>_overrides.dart   List<Override> binding this feature's contracts.
```

**Enforced rules** (`tool/check_boundaries.dart`):
- `core/**` may not import `features/**` or `app/**`.
- `features/A/**` may not import `features/B/**`, nor `app/**`.
- Within a feature: `domain/` imports neither `data/` nor `presentation/`;
  `data/` does not import `presentation/`.
- `features/**` MAY import `core/**`. `app/**` and `main.dart` may import anything.
- Use `package:mvvm/...` imports (very_good_analysis enforces this), never
  relative imports.

---

## 3. State: `ViewState<T>` + the switcher

Every ViewModel exposes a single sealed union, `ViewState<T>` (`core/state/`):

```dart
ViewState.idle()       // nothing requested yet
ViewState.loading()    // request in flight
ViewState.data(T)      // success
ViewState.error(Failure)
ViewState.noInternet() // first-class — AsyncValue cannot express this
```

Render it with `ViewStateSwitcher<T>` (Dart 3 `switch` inside). Only `onData` is
required; the rest fall back to default views:

```dart
ViewStateSwitcher<List<Post>>(
  state: ref.watch(postsViewModelProvider),
  onRetry: () => ref.read(postsViewModelProvider.notifier).load(),
  onData: (posts) => /* your success UI */,
)
```

Do **not** use Riverpod's `AsyncValue` for screen state — it only models
data/loading/error and cannot express `idle`/`noInternet`.

---

## 4. The ViewModel pattern (the ONLY one)

A ViewModel is a code-generated `@riverpod` Notifier whose state is
`ViewState<T>`, mixing in `RemoteStateMixin<T>` for the api→data→state machine:

```dart
// features/<name>/presentation/view_model/<name>_view_model.dart
import 'package:mvvm/core/state/remote_state_mixin.dart';
import 'package:mvvm/core/state/view_state.dart';
import 'package:mvvm/features/<name>/domain/entities/<entity>.dart';
import 'package:mvvm/features/<name>/domain/repositories/<name>_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '<name>_view_model.g.dart';

@riverpod
class FooViewModel extends _$FooViewModel with RemoteStateMixin<List<Foo>> {
  @override
  ViewState<List<Foo>> build() => const ViewState.idle();

  Future<void> load() =>
      runRequest(() => ref.read(fooRepositoryProvider).getFoos());
}
```

`runRequest(Future<Either<Failure, T>> Function())` sets `loading`, then maps the
result: `NoConnectionFailure → noInternet`, any other `Failure → error`,
success → `data`. You never write that boilerplate.

> ⚠️ **`$Notifier` quarantine.** `RemoteStateMixin` is declared
> `on $Notifier<ViewState<T>>`. `$Notifier` is an internal `riverpod_generator`
> type marked "Do not use" — it is the ONE sanctioned-API exception in this
> codebase, and it is confined to `core/state/remote_state_mixin.dart`. **No
> other file may name `$Notifier`.** The public `Notifier` base does NOT work
> with generated Notifiers (verified). After any Riverpod / riverpod_generator
> bump, run the guard test (`test/core/remote_state_mixin_test.dart`); if it
> fails, open a generated `*.g.dart`, read what `_$Xxx` extends, and update the
> `on` clause in that one file.

The View triggers the initial load after the first frame via `ViewReadyMixin`:

```dart
class _FooViewState extends ConsumerState<FooView>
    with ViewReadyMixin<FooView> {
  @override
  void onReady() => ref.read(fooViewModelProvider.notifier).load();
  // ...
}
```

Views get utilities from **extensions on `BuildContext`** (`context.colors`,
`context.showSnackBar(...)`, `context.pushNamed(...)`), never from a `BaseView`
superclass (a widget can extend only one class).

---

## 5. Dependency injection — abstract contracts + composition root

**Every contract is an `abstract interface class`; its provider THROWS and is
bound to a concrete `Impl` by a `ProviderScope` override at startup.** This makes
the composition root the single, authoritative wiring manifest and every
dependency swappable in tests.

```dart
// the contract + its (throwing) provider
abstract interface class FooRepository {
  Future<Either<Failure, List<Foo>>> getFoos();
}

@riverpod
FooRepository fooRepository(Ref ref) => throw UnimplementedError(
  'fooRepositoryProvider must be overridden in ProviderScope — see <feature>_overrides.dart.',
);
```

```dart
// features/<name>/<name>_overrides.dart — the feature's wiring
final List<Override> fooOverrides = <Override>[
  fooRepositoryProvider.overrideWith(
    (ref) => FooRepositoryImpl(remote: ref.watch(fooRemoteDataSourceProvider)),
  ),
  // ...data sources too
];
```

```dart
// lib/main.dart — aggregate core + every feature
final overrides = [...await buildCoreOverrides(), ...fooOverrides];
runApp(ProviderScope(overrides: overrides, child: const App()));
```

- Core contracts (`SecureStore`, `LocalStore`, `RemoteClient`, `TokenProvider`,
  `UnauthorizedHandler`, `ConnectivityService`) are bound in
  `core/bootstrap/bootstrap.dart` (`buildCoreOverrides`, which also opens the
  sembast DB once).
- `Override` is exported by `riverpod_annotation`, **not** `flutter_riverpod`.
- Override closures compose other contracts via `ref.watch(otherProvider)`.

---

## 6. Errors & functional flow

- `Failure` (`core/error/failure.dart`) is the app-wide sealed error vocabulary.
  Every case carries `message`, so `failure.message` always works.
- Repositories/data sources return **`Future<Either<Failure, T>>`** (fpdart).
- `remote_client` request methods return `rc.Either<rc.Failure, rc.BaseResponse<T>>`.
  The **remote data source** is the only place that sees `rc.*`: it calls
  `mapRemoteFailure(...)` (`core/error/failure_mapper.dart`) and unwraps
  `BaseResponse.data`, returning the app's `Either<Failure, Dto>`.
- The **repository** maps DTO → entity and may add cache / offline-fallback
  logic, returning `Either<Failure, Entity>`.

---

## 7. Routing (Navigator 1.0)

- Route names: `core/routing/app_routes.dart` (`Routes.*` constants). Never
  hard-code route strings.
- `app/route_generator.dart` maps names → feature views via `onGenerateRoute`.
  Add new routes here (this is in `app/`, which may import features).
- Navigate with the context extensions: `context.pushNamed(Routes.x, arguments: y)`.
- `rootNavigatorKey` is for navigation from non-widget code.

---

## 8. Remote, storage, env

- **HTTP**: the single `remoteClientProvider` (built in bootstrap). The example
  uses `DirectResponseParser` because JSONPlaceholder returns UNWRAPPED JSON. If
  your API wraps responses as `{success, data, message, meta}`, drop that line to
  use `remote_client`'s default `DefaultResponseParser`.
- **Tokens**: `SecureStore` over `flutter_secure_storage`. `TokenProvider` is
  async and reads it directly.
- **Cache / local data**: `LocalStore` over sembast (`Map<String, Object?>`
  records). DTOs serialise via `toJson`/`fromJson`.
- **Connectivity**: `connectivityServiceProvider` uses `remote_client`'s
  DNS-probe `ConnectivityServiceImpl` (real reachability). `connectivityStatus`
  is a polled `Stream<bool>` for a global offline banner.
- **Env**: `core/config/app_config.dart` is generated by `envied` from `.env`.
  Add a field as `@EnviedField(varName: 'X')` and reference `_AppConfig.x`. For
  secrets use `@EnviedField(obfuscate: true)`, then `git rm --cached .env` and
  gitignore it.

---

## 9. Quality gates (before every commit)

1. `dart run build_runner build` (codegen current).
2. `dart format .`.
3. `flutter analyze` → **No issues found** (very_good_analysis is strict:
   package imports, 80-col, trailing commas, no `print`, etc.).
4. `dart run tool/check_boundaries.dart` → **OK**.
5. `flutter test` green.

---

## 10. HOW TO ADD A FEATURE (runbook)

Mirror `lib/features/posts/`. For a feature `bar` with entity `Bar`:

1. **Entity** — `domain/entities/bar.dart`: `@freezed abstract class Bar` (no
   JSON).
2. **Repository contract** — `domain/repositories/bar_repository.dart`:
   `abstract interface class BarRepository` returning
   `Future<Either<Failure, ...>>`, plus a throwing `@riverpod barRepository`.
3. **DTO** — `data/dtos/bar_dto.dart`: `@freezed abstract class BarDto` with
   `fromJson`, and an `extension BarDtoMapper { Bar toEntity() => ... }`.
4. **Remote data source** — `data/sources/bar_remote_data_source.dart`: abstract
   + `Impl(rc.RemoteClient)` (confine `rc.*`, use `mapRemoteFailure`) + throwing
   provider.
5. **Local data source** (if caching) — `data/sources/bar_local_data_source.dart`:
   abstract + `Impl(LocalStore)` + throwing provider.
6. **Repository impl** — `data/repositories/bar_repository_impl.dart`: maps
   DTO→entity, cache/offline logic.
7. **ViewModel** — `presentation/view_model/bar_view_model.dart`: `@riverpod` +
   `RemoteStateMixin<T>` (see §4).
8. **View(s)** — `presentation/view/bar_view.dart`: `ConsumerStatefulWidget` +
   `ViewReadyMixin`, render via `ViewStateSwitcher`.
9. **Overrides** — `bar_overrides.dart`: bind every contract from steps 2/4/5/6.
10. **Wire** — add `...barOverrides` to `main.dart`; add routes to
    `app/route_generator.dart` + `core/routing/app_routes.dart`.
11. **Generate + verify** — `dart run build_runner build`, then run all of §9.
12. **Commit** — see §11.

---

## 11. Git / commit conventions

- Author: **`irshadio <irshad.kp@icloud.com>`** (set per-repo; do not change).
- Work on the **`dev`** branch. One focused commit per logical unit.
- Conventional commits: `feat(<scope>): ...`, `fix(...)`, `refactor(...)`,
  `build: ...`, `test: ...`, `docs: ...`.
- Never commit generated files (`*.g.dart`, `*.freezed.dart`) — they are
  git-ignored.
- A commit must pass all of §9.

---

## 12. Do NOT

- ❌ Use `.when` / `.map` / `.maybeWhen` on Freezed unions or `AsyncValue` — use
  `switch`.
- ❌ Name `$Notifier` anywhere except `core/state/remote_state_mixin.dart`.
- ❌ Let a `rc.*` (`remote_client`) type appear outside `data/`.
- ❌ Construct an `Impl` directly in a feature — bind it via an override.
- ❌ Import one feature from another, or import features/app from core.
- ❌ Use relative imports — use `package:mvvm/...`.
- ❌ Add `AsyncValue` screen state, `go_router`, `dartz`, or a `usecase/` layer.
- ❌ Commit with a non-clean `flutter analyze` or a failing boundary check.

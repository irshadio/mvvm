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
  main.dart            Default entrypoint -> runMvvmApp (+ main_<flavour>.dart).
  app/                 Top layer. MAY import anything (core + features).
    app.dart           MaterialApp (Navigator 1.0, onGenerateRoute).
    run_app.dart       Composition root: global error handlers, builds the
                       core+feature overrides, runs ProviderScope.
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
ViewState.idle()                        // nothing requested yet
ViewState.loading({T? previous})        // in flight; carries last data
ViewState.data(T)                       // success
ViewState.error(Failure, {T? previous}) // failure; carries last data
ViewState.noInternet({T? previous})     // first-class — AsyncValue can't model
```

`loading`/`error`/`noInternet` carry the last loaded data as `previous` so a
**refresh** is non-destructive: the switcher keeps showing data while reloading
and after a failed reload, instead of blanking to a spinner. `RemoteStateMixin`
fills `previous` automatically; read the current data anywhere with
`state.dataOrNull`.

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

Because a failed *refresh* keeps the stale data on screen (the switcher does not
show the error view when `previous` exists), every data View MUST also surface
those failures with one line in `build`, or they are swallowed silently:

```dart
ref.listenRefreshFailures(postsViewModelProvider, context); // -> toast on refresh error
```

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

`runRequest(Future<Either<Failure, T>> Function())` snapshots the current data,
sets `loading(previous:)`, awaits, and — if the notifier is still mounted
(`ref.mounted`, so a request finishing after the View is popped does not throw)
— maps the result: `NoConnectionFailure → noInternet`, any other
`Failure → error`, success → `data`, carrying `previous` into the failure
states. You never write that boilerplate.

> ⚠️ **`$Notifier` quarantine.** `RemoteStateMixin` is declared
> `on $Notifier<ViewState<T>>`. `$Notifier` is an internal `riverpod_generator`
> type marked "Do not use" — it is the sanctioned-API exception in this
> codebase, confined to **`core/state/`**: only `remote_state_mixin.dart` and
> its write-side twin `mutation_state_mixin.dart` (§4b) may name it. **No other
> file may name `$Notifier`.** The public `Notifier` base does NOT work with
> generated Notifiers (verified). After any Riverpod / riverpod_generator bump,
> run both guard tests (`test/core/remote_state_mixin_test.dart`,
> `test/core/mutation_state_mixin_test.dart`); if one fails, open a generated
> `*.g.dart`, read what `_$Xxx` extends, and update the `on` clause in that one
> file.

The View triggers the initial load after the first frame via `ViewReadyMixin`:

```dart
class _FooViewState extends ConsumerState<FooView>
    with ViewReadyMixin<FooView> {
  @override
  void onReady() => ref.read(fooViewModelProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    ref.listenRefreshFailures(fooViewModelProvider, context); // §3 — required
    final state = ref.watch(fooViewModelProvider);
    return ViewStateSwitcher<List<Foo>>(state: state, onData: ...);
  }
}
```

Views get utilities from **extensions on `BuildContext`** (`context.colors`,
`context.showSnackBar(...)`, `context.pushNamed(...)`), never from a `BaseView`
superclass (a widget can extend only one class).

---

## 4b. The mutation pattern (writes — create / update / delete)

Reads use `ViewState<T>` + `RemoteStateMixin`. **Writes use the parallel pair
`SubmissionState<T>` + `MutationStateMixin`** (`core/state/`). The reference is
`features/posts/` → `CreatePostViewModel` / `create_post_view.dart`.

`SubmissionState<T>` models a *submission* lifecycle, not a display one:

```dart
SubmissionState.idle()              // pristine form
SubmissionState.inProgress()        // submit in flight
SubmissionState.success(T value)    // created/updated value
SubmissionState.failure(Failure)    // typed failure
```

The **form fields live in the View** (a `Form` + `TextEditingController`s with
validators) — the ViewModel state only tracks the submission, so it can express
“fields on screen *and* a submit in flight.” The ViewModel mirrors §4:

```dart
@riverpod
class CreateFooViewModel extends _$CreateFooViewModel
    with MutationStateMixin<Foo> {
  @override
  SubmissionState<Foo> build() => const SubmissionState.idle();

  Future<void> submit(FooInput input) =>
      runMutation(() => ref.read(fooRepositoryProvider).createFoo(input));
}
```

`runMutation` sets `inProgress`, awaits, and — if still mounted — maps
`success`/`failure`. The View **watches** the state to disable the button while
`state.isInProgress`, and **reacts once** to the terminal transition with the
required one-liner (the write-side `listenRefreshFailures`):

```dart
ref.listenSubmission(
  createFooViewModelProvider,
  context,
  onSuccess: (foo) { context.pop(); context.showSnackBar('Created'); },
  // onFailure defaults to an error snackbar with failure.message
);
```

The repository/data-source layers are unchanged (§5–§6): a new
`createFoo(FooInput)` returning `Future<Either<Failure, Foo>>`, the remote source
`POST`s and confines `rc.*`. Do **not** add `AsyncValue`/`AsyncNotifier` for
form state — `SubmissionState` is the one shape.

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
// lib/app/run_app.dart — aggregate core + every feature (shared by all flavours)
final overrides = [
  ...await buildCoreOverrides(env: env, logger: logger, reporter: reporter),
  ...fooOverrides,
];
runApp(ProviderScope(overrides: overrides, child: const App()));
```

- The aggregation lives in `lib/app/run_app.dart` (`runMvvmApp(env)`), called by
  each flavour entrypoint (`main.dart`, `main_dev.dart`, …). It also installs the
  global error handlers. It is in `app/` — not `core/` — because it references
  `App` (core may never import app). See §8 (flavours) and `docs/FLAVORS.md`.
- Core contracts (`AppLogger`, `ErrorReporter`, `SecureStore`, `LocalStore`,
  `RemoteClient`, `TokenProvider`, `UnauthorizedHandler`, `ConnectivityService`)
  are bound in `core/bootstrap/bootstrap.dart` (`buildCoreOverrides`, which also
  opens the sembast DB once). It takes the active `AppEnvironment` plus the
  `AppLogger`/`ErrorReporter` instances (created in `run_app.dart` so the global
  handlers share them).
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
  is a polled `Stream<bool>`; the global offline banner (`ConnectivityBanner`,
  mounted via `MaterialApp.builder` in `app.dart`) watches it.
- **Env**: `core/config/app_config.dart` is generated by `envied` from `.env`.
  Add a field as `@EnviedField(varName: 'X')` and reference `_AppConfig.x`. For
  secrets use `@EnviedField(obfuscate: true)`, then `git rm --cached .env` and
  gitignore it.
- **Observability**: `AppLogger` (`core/logging`) for structured logs (never
  `print`); `ErrorReporter` (`core/error/error_reporter.dart`) is the crash sink
  wired to `FlutterError.onError` + `PlatformDispatcher.onError` in
  `run_app.dart` — swap `LoggingErrorReporter` for a Sentry/Crashlytics impl
  there. Both are abstract contracts read via `ref.watch`.
- **Flavours**: `dev`/`staging`/`prod` via per-flavour entrypoints
  (`main_<flavour>.dart`) + `AppEnvironment`/`EnvConfig` (`core/config`). Android
  `productFlavors` are wired; iOS schemes are documented. **`docs/FLAVORS.md`.**
- **Toolchain note**: `freezed` / `riverpod_generator` are pinned to *prerelease*
  (`-dev`) versions (a deliberate choice). After any bump, re-run the full gate —
  especially the `$Notifier` guard test (§4).

---

## 9. Quality gates (before every commit)

1. `dart run build_runner build` (codegen current).
2. `dart format .`.
3. `flutter analyze` → **No issues found** (very_good_analysis is strict:
   package imports, 80-col, trailing commas, no `print`, etc.).
4. `dart run tool/check_boundaries.dart` → **OK**.
5. `dart run tool/check_loc.dart` → every file ≤ 200 lines.
6. `flutter test` green.

`dart run tool/gate.dart` runs steps 1 and 3–6 in order; the commit hook and
GitHub Actions (`.github/workflows/ci.yml`) both run it, so a green PR satisfies
every gate.

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
10. **Wire** — add `...barOverrides` to `app/run_app.dart`; add routes to
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
- ❌ Name `$Notifier` anywhere except `core/state/remote_state_mixin.dart` and
  `core/state/mutation_state_mixin.dart`.
- ❌ Let a `rc.*` (`remote_client`) type appear outside `data/`.
- ❌ Construct an `Impl` directly in a feature — bind it via an override.
- ❌ Import one feature from another, or import features/app from core.
- ❌ Use relative imports — use `package:mvvm/...`.
- ❌ Add `AsyncValue` screen state, `go_router`, `dartz`, or a `usecase/` layer.
- ❌ Commit with a non-clean `flutter analyze` or a failing boundary check.

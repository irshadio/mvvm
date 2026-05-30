# Architecture

An enterprise-grade, **agent-first** MVVM architecture for Flutter. The patterns
are intentionally rigid: an automated agent should be able to add a feature by
copying one shape, and a human should be able to review it quickly. The
operational rules live in [`CLAUDE.md`](../CLAUDE.md); this document explains the
*why*.

## Goals

- **Dogmatic MVVM** — View ↔ ViewModel ↔ Model (repository + sources). No
  use-case/interactor layer (the official Flutter guidance treats use-cases as
  optional, added only to share logic between ViewModels).
- **Scalable, feature-first modularity** with compiler- and tool-enforced
  boundaries.
- **Deterministic for agents** — one ViewModel shape, one state type, one DI
  mechanism, one error type.
- **Functional core** — typed failures and `Either`, no throwing across layers.

## Layered structure

```
            ┌─────────────────────────────────────────────┐
  app/      │ main.dart · App (MaterialApp) · RouteGenerator│  composition + nav
            └───────────────┬───────────────┬──────────────┘
                            │ may import     │
            ┌───────────────▼───────┐   ┌────▼───────────────────────────┐
 features/  │ presentation (View +  │   │  ... another feature (isolated) │
            │ ViewModel)            │   └─────────────────────────────────┘
            │   ▼ depends on        │
            │ domain (entity +      │   feature → feature imports are FORBIDDEN
            │ repository contract)  │
            │   ▲ implemented by    │
            │ data (DTO, sources,   │
            │ repository impl)      │
            └───────────────┬───────┘
                            │ may import (never the reverse)
            ┌───────────────▼──────────────────────────────┐
  core/     │ state · error · network · storage · routing · │  generic, reusable
            │ presentation · bootstrap · config · utils     │
            └───────────────────────────────────────────────┘
```

Boundaries are enforced by `tool/check_boundaries.dart` (run in the quality
gate). See [`CLAUDE.md` §2](../CLAUDE.md).

## The reusable data flow (api → data → state → view)

```
RemoteClient.get<Dto>()                      rc.Either<rc.Failure, BaseResponse<Dto>>
        │  (remote_client; rc.* confined to the data source)
        ▼
RemoteDataSource  ── mapRemoteFailure + unwrap ──▶  Either<Failure, Dto>
        ▼
Repository  ── DTO→entity, cache / offline fallback ──▶  Either<Failure, Entity>
        ▼
ViewModel (@riverpod + RemoteStateMixin)  ── runRequest() ──▶  ViewState<Entity>
        ▼
View (ViewStateSwitcher)  ──▶  loading / data / error / noInternet / idle widgets
```

Every feature reuses this exact spine; only the DTO, entity, endpoints and UI
change.

## Key decisions & rationale

| Decision | Why |
| --- | --- |
| **Riverpod 3 + `riverpod_generator` Notifiers as ViewModels** | Compile-time-safe DI/state; codegen removes provider boilerplate. ([riverpod.dev](https://riverpod.dev/docs/whats_new)) |
| **`RemoteStateMixin` `on $Notifier`** | The api→data→state machine is shared via a mixin (a requirement). A mixin only attaches to a generated Notifier through the internal `$Notifier`; the public `Notifier` base does not match generated output — verified empirically on the installed toolchain. The dependency on the "do not use" `$Notifier` is **quarantined to one file** and guarded by a test. ([riverpod#3546](https://github.com/rrousselGit/riverpod/issues/3546)) |
| **Custom `ViewState<T>` over `AsyncValue`** | Riverpod 3's `AsyncValue` is sealed but has exactly three cases (data/loading/error); it cannot express `idle` or `noInternet` as first-class states. A Freezed sealed union can. Like `AsyncValue.copyWithPrevious`, `loading`/`error`/`noInternet` carry the last data as `previous`, so a refresh never blanks the screen. ([AsyncValue docs](https://pub.dev/documentation/riverpod/latest/riverpod/AsyncValue-class.html)) |
| **Dart 3 `switch`, not `.when`/`.map`** | Freezed 3 made the generated pattern-matching helpers legacy/discouraged in favour of native pattern matching. ([freezed](https://pub.dev/packages/freezed)) |
| **fpdart `Either<Failure, T>`** | Functional error handling without exceptions across layers; richer than `remote_client`'s minimal `Either`, and decoupled from the transport package. |
| **Abstract contracts + `ProviderScope` overrides (composition root)** | Every contract is swappable/mockable; all wiring is readable in one place (`bootstrap` + per-feature override lists). |
| **`remote_client` (vendored HTTP client)** | Provides retry, auth hooks (`TokenProvider`/`UnauthorizedHandler`), typed `Failure`, and **real DNS-probe reachability** — so no separate `connectivity_plus` is needed. `connectivity_plus` only reports interface type, not reachability (captive portals). ([connectivity_plus](https://pub.dev/packages/connectivity_plus)) |
| **Navigator 1.0 + `onGenerateRoute`** | Explicit, centralised routing with typed arguments (chosen over `go_router`). |
| **very_good_analysis + `check_boundaries.dart`** | Strict, STABLE lint baseline. Analyzer plugins (`custom_lint`/`riverpod_lint`/`import_rules`) currently can't co-exist at Riverpod 3.2 + Freezed 3 + the current analyzer, so boundaries are enforced by a transparent script instead. |
| **sembast (local) + flutter_secure_storage (tokens) + envied (env)** | Lightweight local DB; OS-keystore-backed secrets; type-safe, generated env config. |

## Stack

| Concern | Package |
| --- | --- |
| State / DI | `flutter_riverpod` 3, `riverpod_annotation` / `riverpod_generator` |
| Models / unions | `freezed` (+ `json_serializable`) |
| Functional | `fpdart` |
| HTTP | `remote_client` (wraps Dio) |
| Local DB | `sembast` |
| Secrets | `flutter_secure_storage` |
| Env config | `envied` |
| Observability | `dart:developer` (`AppLogger`) + vendor-agnostic `ErrorReporter` |
| Flavours | per-flavour entrypoints + `AppEnvironment` (+ Android `productFlavors`) |
| Lints | `very_good_analysis` + `tool/check_boundaries.dart` + `tool/check_loc.dart` |

## Reference feature

`lib/features/posts/` is the canonical example (remote fetch + sembast cache +
offline fallback, list + detail). Copy it when adding a feature; the step-by-step
runbook is [`CLAUDE.md` §10](../CLAUDE.md).

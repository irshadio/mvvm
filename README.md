# mvvm

Enterprise-grade, **agent-first MVVM architecture** for Flutter — Riverpod 3 +
Freezed + fpdart + `remote_client` + sembast. Built so an automated agent
(Claude Code / Opus) can add features by following one fixed set of patterns,
and a human can review them quickly.

## Getting started

```bash
flutter pub get
dart run build_runner build   # generate *.g.dart / *.freezed.dart (REQUIRED)
flutter run --flavor dev -t lib/main_dev.dart --dart-define=APP_ENV=dev
```

> The app has `dev`/`staging`/`prod` flavours, so pass `--flavor` (a bare
> `flutter run` is rejected once Android flavours exist). See
> [docs/FLAVORS.md](docs/FLAVORS.md).

> Generated files are git-ignored — always run `build_runner` after cloning or
> editing an annotated file. `.env` (consumed by `envied`) is committed here with
> a public API URL; replace it / obfuscate for real secrets.

## Docs

- **[CLAUDE.md](CLAUDE.md)** — the authoritative rules agents follow: state model,
  the single ViewModel pattern, DI/composition root, import boundaries, and the
  step-by-step "add a feature" runbook.
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — layered structure, the
  api→data→state→view flow, and the rationale (with sources) behind each decision.
- **[docs/FLAVORS.md](docs/FLAVORS.md)** — the dev/staging/prod build flavours,
  how to run each, and the manual iOS scheme setup.

## Quality gates

```bash
dart run tool/gate.dart   # build_runner + analyze + boundaries + LOC + test
```

The same gate runs in the commit hook and in CI
(`.github/workflows/ci.yml`), so a green PR satisfies every check. Individually:

```bash
flutter analyze                      # very_good_analysis (strict)
dart run tool/check_boundaries.dart  # feature/layer import boundaries
dart run tool/check_loc.dart         # every file ≤ 200 lines
flutter test
```

## Reference feature

`lib/features/posts/` — remote fetch + sembast cache + offline fallback, with a
list and detail screen. It is the canonical template; copy it to add a feature.

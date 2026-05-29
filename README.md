# mvvm

Enterprise-grade, **agent-first MVVM architecture** for Flutter — Riverpod 3 +
Freezed + fpdart + `remote_client` + sembast. Built so an automated agent
(Claude Code / Opus) can add features by following one fixed set of patterns,
and a human can review them quickly.

## Getting started

```bash
flutter pub get
dart run build_runner build   # generate *.g.dart / *.freezed.dart (REQUIRED)
flutter run
```

> Generated files are git-ignored — always run `build_runner` after cloning or
> editing an annotated file. `.env` (consumed by `envied`) is committed here with
> a public API URL; replace it / obfuscate for real secrets.

## Docs

- **[CLAUDE.md](CLAUDE.md)** — the authoritative rules agents follow: state model,
  the single ViewModel pattern, DI/composition root, import boundaries, and the
  step-by-step "add a feature" runbook.
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — layered structure, the
  api→data→state→view flow, and the rationale (with sources) behind each decision.

## Quality gates

```bash
flutter analyze                      # very_good_analysis (strict)
dart run tool/check_boundaries.dart  # feature/layer import boundaries
flutter test
```

## Reference feature

`lib/features/posts/` — remote fetch + sembast cache + offline fallback, with a
list and detail screen. It is the canonical template; copy it to add a feature.

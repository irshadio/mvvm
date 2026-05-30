# Build flavours (dev / staging / prod)

The app ships three flavours. Each has its own entrypoint, its own
`AppEnvironment`/`EnvConfig` (API base URL, log level, …), and — on Android — a
distinct `applicationId` so all three install side by side.

| Flavour | Entrypoint            | `APP_ENV`  | Android applicationId      |
| ------- | --------------------- | ---------- | -------------------------- |
| dev     | `lib/main_dev.dart`     | `dev`      | `com.example.mvvm.dev`     |
| staging | `lib/main_staging.dart` | `staging`  | `com.example.mvvm.staging` |
| prod    | `lib/main_prod.dart`    | `prod`     | `com.example.mvvm`         |

`lib/main.dart` is a flavour-less default that resolves `APP_ENV` (default
`dev`) — handy for desktop/web where native flavours don't apply.

## Run / build

```bash
flutter run   --flavor dev     -t lib/main_dev.dart     --dart-define=APP_ENV=dev
flutter run   --flavor staging -t lib/main_staging.dart --dart-define=APP_ENV=staging
flutter build apk --flavor prod -t lib/main_prod.dart   --dart-define=APP_ENV=prod
```

> ⚠️ Once Android flavours exist, a bare `flutter run` (no `--flavor`) is
> rejected by the Flutter tool. Use a launch config (`.vscode/launch.json`) or
> always pass `--flavor`. `flutter test` and `flutter analyze` do **not** need a
> flavour, so the CI gate is unaffected.

## What is wired

- **Dart** — `lib/core/config/app_environment.dart` (`AppEnvironment` + `EnvConfig`),
  the three entrypoints, and `app/run_app.dart` (shared composition root).
- **Android** — `android/app/build.gradle.kts` `productFlavors` (the `env`
  dimension, with `applicationIdSuffix` / `versionNameSuffix`).
- **VS Code** — `.vscode/launch.json` configs.

## Per-flavour values (next steps)

`EnvConfig` currently points all flavours at the same demo API. Give each its
own `apiBaseUrl` there. For per-flavour **secrets**, create `.env.dev`,
`.env.staging`, `.env.prod` and generate a separate `@Envied` class per file,
then select by flavour in `EnvConfig`.

## iOS (manual — not auto-applied)

Editing `project.pbxproj` by hand is risky, so iOS schemes are intentionally
left for you to add in Xcode:

1. **Build configurations** — duplicate `Debug`/`Release`/`Profile` into
   `Debug-dev`, `Release-dev`, … for each flavour (Project ▸ Info ▸
   Configurations).
2. **Schemes** — add a scheme per flavour (`dev`, `staging`, `prod`), each using
   its matching configurations. Mark them *Shared* so they're committed.
3. **Bundle identifier** — set `PRODUCT_BUNDLE_IDENTIFIER` per configuration
   (e.g. `com.example.mvvm.dev`) via an `.xcconfig` or build settings.
4. Flutter matches `--flavor dev` to the **scheme** named `dev`.

See the Flutter flavours guide: <https://docs.flutter.dev/deployment/flavors>.

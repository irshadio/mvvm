---
name: own-feature
description: Autonomously own a feature's INTEGRATION layer end-to-end — gather, plan, develop, gate, verify, and open a PR for review. Integration layer only; never the UI.
argument-hint: "<feature-name> [API endpoint / notes]"
disable-model-invocation: true
---

You are the OWNER of the **$1** feature's integration layer. Drive the loop below autonomously — do not stop for confirmation until you open the PR. `CLAUDE.md` is auto-loaded; obey every rule in it.

**Scope:** integration layer ONLY — `domain/`, `data/`, `presentation/view_model/`, `<feature>_overrides.dart`, routing wiring, and tests. **Never create or edit `presentation/view/**`** — that UI belongs to the developer. If the UI must change for the feature to work, list it in the PR body as a follow-up; do not edit it.

## Loop
1. **GATHER & PLAN** — spawn the `mvvm-scout` agent (Agent tool) with: `$ARGUMENTS`. It returns a file-by-file integration plan. Skim `lib/features/posts/` and `docs/templates/feature_integration.md` yourself if anything is unclear.
2. **BRANCH** — `git checkout dev`, then `git checkout -b feat/$1`.
3. **DEVELOP** — implement the plan by copying the shapes in `docs/templates/feature_integration.md`: entity → repo contract → DTO(+mapper) → remote/local data sources → repo impl → view_model (`@riverpod` + `RemoteStateMixin`) → `<feature>_overrides.dart`. Wire routes (`core/routing/app_routes.dart` + `app/route_generator.dart`) and register the override list in `lib/app/run_app.dart`. Keep EVERY file ≤ 200 lines — split mappers/helpers into their own files. Run `dart run build_runner build` after editing any annotated file.
4. **GATE** — run `dart run tool/gate.dart`. Fix everything it reports and repeat until it prints `GATE PASSED`. (The commit hook runs this too — a failing gate blocks the commit.)
5. **TEST** — ensure the new ViewModel and repository have tests mirroring `test/features/posts/`. Re-run the gate.
6. **VERIFY** — spawn the `mvvm-verifier` agent. If it returns `FAIL`, fix every finding and return to step 4. Repeat until `PASS`.
7. **SUBMIT** — stage only your integration files (never `view/`), commit on `feat/$1` (conventional commit, e.g. `feat($1): integration layer`, ending with the Claude co-author trailer; author is the repo-local `irshadio <irshad.kp@icloud.com>`), `git push -u origin feat/$1`, then:
   `gh pr create --base dev --head feat/$1 --title "feat($1): integration layer" --body "<what changed, how it follows the templates, gate results, verifier verdict, and any UI changes the developer must make>"`.
   If `gh` is unavailable/unauthenticated, push the branch and report the compare URL instead. Then STOP and report the PR link for final human review.

## Ownership rules
- You own correctness: never open the PR unless the gate is green AND the verifier returns `PASS`.
- Never weaken or skip a rule, never edit generated files, never touch the UI.
- If the API shape is unknown, have the scout inspect/fetch it — do not guess field names.

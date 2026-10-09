# AGENTS.md — instructions for agents working in this repo

`promptite` is a single flat Dart package: a token-lean prompt tightener with a
public library (`lib/`) and a CLI (`bin/`) that targets pub.dev. Doctrine comes
from the upstream **dart-flutter-bible** (standards repo,
`github.com/staylorx/dart-flutter-bible`). Per bible §1 (D.R.Y.), this file
records only this repo's deviations and local wiring — it points at doctrine
and `BACKLOG.md`, it does not restate rules.

## What to do before you work here

- Read `BACKLOG.md` first. It is the item-by-item build/analysis and
  dart-flutter-bible deviation list with open/closed status, and it is part of
  the gate: close or add deviations there (and in `CHANGELOG.md`), never in
  prose here.
- This package intentionally does **not** adopt several bible rules — the
  pub-workspace/domain/usecases/datasource topology (§3), `shouldly`
  Given/When/Then tests (§6), a per-layer sealed `Failure` hierarchy with value
  equality (§4), `dart_arch_test` (§2/§9). Those are judged, deliberate
  deviations for a dependency-free CLI with no persistence, and each is tracked
  in `BACKLOG.md`. Do not "fix" them without recording the decision there.

## Done means shipped (velocity)

When the work is green gate — everything formatted, analyzed with zero
diagnostics, covered, tested, CI'd clean, and good enough to report "done" —
ship it yourself without asking: commit, push to `main`, and delete the branch.
No waiting for a checkpoint prompt. Eventually we move to PRs; for now velocity
is the default, and finishing a task always implies commit + push unless the
user says otherwise.

## Error style (declared)

The public API returns fpdart `Either<Failure, String>` (FP tuples) —
`generateTightPromptEither` and the `taskPrompt`/`contextPrompt`/`filesPrompt`
helpers. `Failure` is the failure hierarchy in `lib/src/failure.dart`. The one
exception: `generateTightPrompt` throws — it is the UX seam the CLI (`bin/`)
sits on, which is the bible's permitted UI-ring throw. (bible §4: the style is
named in the barrel, the README, and here because of that exception.)

## Local wiring (this machine)

- Build the Windows binary with `mkdir -p build` first, then
  `dart compile exe bin/promptite.dart -o build/promptite.exe`. `dart compile
  exe` does **not** create its output directory and `build/` is gitignored, so
  a clean checkout fails with `PathNotFoundException: ... build\promptite.exe`
  without the mkdir. The `windows` CI lane and `tool/windows_smoke.sh` already
  do this; `bash tool/windows_smoke.sh` is how the artifact is validated.
- Dart SDK is managed via fvm (`C:/Users/stayl/fvm/default/bin`) — `dart` is
  not on `PATH` in a bare shell on this box; export it first.
- Git remotes use SSH (`git@github.com:staylorx/promptite.git`); there is no
  `gh` CLI.
- Keep the working tree clean before committing: `dart format`,
  `dart analyze --fatal-infos --fatal-warnings` (zero diagnostics of any
  severity), `dart test`. Line endings are LF, enforced by `.gitattributes`.

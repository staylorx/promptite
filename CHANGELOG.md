# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `lib/src/cli_text.dart` — the CLI ring's text, split out of `bin/promptite.dart` so it is unit-testable:
  `invocationLabel` names the copy of the tool that is running, `renderUsage` builds the banner, and
  `userFacingMessage` renders one thrown object as the single line the user sees. It imports no `dart:io`;
  `bin/` supplies the platform values.
- `test/cli_test.dart` — 16 end-to-end tests that run the **compiled** binary (`dart compile exe` into a temp
  directory in `setUpAll`) rather than `dart run`, so the artifact the README tells a Windows user to build is
  the thing under test: both README invocations, the `--script`/`--script=<bool>` repair, the exit codes, the
  stdout/stderr split, UTF-8 arguments, LF-only bytes, and a run from a foreign directory with the Dart SDK off
  `PATH`.
- `test/cli_text_test.dart` — unit tests for the banner and message rendering (invocation naming on both a
  compiled binary and `dart run`, no `dart run` in a binary's banner, no doubled type prefix).
- `test/promptite_test.dart` — `Left` coverage for the failure paths the suite never touched (empty task,
  empty context, empty file list, angle brackets in a file name) plus the `Right` files tag.
- `tool/windows_smoke.sh` — the Windows validation lane, and now the whole `windows` CI job. It rebuilds the
  binary **from a tree with no `build/`** and then runs 26 checks over the artifact. Run it by hand with
  `bash tool/windows_smoke.sh`.
- Windows build target: `pubspec.yaml` declares `executables:` and a native Windows console binary is
  compiled with `dart compile exe`; `README.md` gained a "Building on Windows" section with the build commands
  and a verify step.
- `.github/workflows/ci.yml` — this repo's first CI. The `verify` job runs `dart format --set-exit-if-changed`,
  `dart analyze --fatal-infos --fatal-warnings`, `dart test` and `dart pub publish --dry-run`; the `windows`
  job compiles the binary on `windows-latest` and smoke-tests it against the three README invocations plus the
  missing-`--task` exit code. The bible §9 step 10 gate now runs on every pull request.
- `test/cli_test.dart` — 15 end-to-end CLI tests that run the **compiled** binary (rebuilt with
  `dart compile exe` in `setUpAll`, so a stale `.exe` cannot report old behaviour): both `README.md` invocations,
  the usage banner and the exit-0/exit-1 paths, the `--script` typo repair, the byte-stream properties (UTF-8
  passthrough, LF-only line endings) and a run from a foreign directory with no Dart SDK on `PATH`. `test/` now
  exercises the CLI's argument parsing, which only the Windows CI lane's shell smoke test had ever touched.
- `BACKLOG.md` recording open build/analysis issues and dart-flutter-bible deviations.
- Completed `BACKLOG.md` in the 2026-09-25 audit pass with the findings the first pass missed: the direct
  `package:promptite/src/...` imports in `bin/promptite.dart:5`, `test/promptite_test.dart:4` and
  `lib/src/promptite.dart:2`; the dead `_showFriendlyError` ternary and the undocumented
  `--script` -> `--strict` rewrite; the never-constructed `ConfigFailure`/`CliFailure`/`ApiFailure` leaves;
  the missing `examples/` for a pub.dev-targeted package; and the duplicated package description in
  `README.md:1` vs `pubspec.yaml:2`.
- `example/example.dart` — a runnable, CI-tested example of using the package/cli: it shows the library API
  (fpdart `Either<Failure, String>`, the token estimate, handling a `Left` failure as a value) and, in its
  header, the equivalent CLI invocation (`dart run bin/promptite.dart ...` and the compiled `promptite.exe`).
  `test/examples_test.dart` runs it under `dart test`, so the example cannot rot into a file nobody executes.
  The directory is `example/` (singular) because `dart pub publish --dry-run` enforces the pub layout
  convention — plural `examples/` trips a "rename the top-level examples directory to example" warning — so
  the package keeps its 0-warnings publish gate.
- `AGENTS.md` — records this repo's deviations (referencing `BACKLOG.md`) and local wiring, and declares the
  package error style (fpdart `Either` with a single throwing CLI seam) per the dart-flutter-bible §4. The
  earlier write had been refused by a writing-agent guardrail for want of operator approval; this one is
  operator-approved and lands both `BACKLOG.md` items it covers as closed.

### Changed

- `.github/workflows/ci.yml` — the `windows` job's compile and smoke steps are replaced by a single
  `bash tool/windows_smoke.sh` step, so the lane CI runs and the lane a developer runs cannot drift apart. The
  script deletes `build/` before compiling, so the clean-checkout case the CI job tripped on is measured on every
  run rather than only on a fresh clone.
- `bin/promptite.dart` — imports the `package:promptite/promptite.dart` barrel instead of reaching into
  `package:promptite/src/...`, which closes that item in `BACKLOG.md`; `printUsage` and `_showFriendlyError`
  now delegate their text to `lib/src/cli_text.dart`.
- `lib/src/promptite.dart` — `taskPrompt`, `contextPrompt` and `filesPrompt` construct their `Failure` values
  directly instead of throwing inside `Either.tryCatch` and reading the message back out of
  `Exception.toString()`. Same `Either` contract, one fewer indirection, and the messages are now the bare
  text the user is meant to read.
- `README.md` — the Windows build is three commands, not one: the `mkdir -p build` line is now documented as
  required, with the failure it prevents; the `--script=<bool>` forms are documented; and the section points at
  `tool/windows_smoke.sh` as the verify step instead of a bare `./build/promptite.exe` line.
- `pubspec.yaml` — `executable: promptite`, a key pub does not recognize, replaced with the correct
  `executables:` map (`promptite: promptite`).
- `pubspec.yaml` — description rewritten from the bootstrap-template "sample command-line application" text
  into what the tool actually does; `README.md` no longer restates it, so the package is described once.
- `analysis_options.yaml` — dropped the obsolete `analyzer.strong-mode` block (Dart 3 replaced those keys with
  `language.strict-casts`/`strict-raw-types`, which were already set; the old keys were dead config) and the
  leftover commented-out `exclude` entries.
- `analysis_options.yaml` — dropped `errors: prefer_const_constructors: ignore`, which contradicted the
  `prefer_const_constructors` linter rule and disabled a rule in the config file (bible §2 bans both). Two
  `Right(...)` constructions in `lib/src/promptite.dart` became `const` to satisfy the rule that is now live.
- `README.md` — Usage no longer opens with "sample command-line application" boilerplate; it documents the
  `--script` repair and points at the Windows build section.
- Normalized this file to the Keep a Changelog format (was a bare `## 1.0.0` heading with no date and no
  change-type headings).
- Corrected the `[1.0.0]` release date: it read `2026-09-24`, which is the audit date; both 1.0.0 commits are
  dated `2026-01-28` (`git log`: `71250a8`, `f3ce7ba`).
- Corrected a claim in `BACKLOG.md` that `Failure.message` is mutable; `lib/src/failure.dart:2` declares it
  `final`.

### Fixed

- `bin/promptite.dart` — the compiled binary's own usage banner told the user to run
  `dart run bin/promptite.dart`, an invocation a Windows user of `promptite.exe` may not have an SDK for. The
  banner now names the running copy (`promptite.exe <flags>`, examples included) and says `dart run …` only when
  the script really is being run by the VM.
- `bin/promptite.dart` — a failure report doubled the Dart type prefix:
  `Error: Exception: Failed to generate prompt: Exception: Invalid characters in file names`. It now reads
  `Error: Failed to generate prompt: Invalid characters in file names`.
- `dart pub publish --dry-run` exited 65 on the unrecognized `executable:` pubspec key; with the correct
  `executables:` map the dry run reaches "Package has 0 warnings" and exit 0.
- `bin/promptite.dart` — `_showFriendlyError`'s `(error is Error || error is Exception)` ternary had two
  identical arms, so the type test could never change the output. Removed; newline flattening now happens on
  the `toString()` call itself.
- `.github/workflows/ci.yml` — the `windows` job failed on **every** run since the lane was added and never reached
  its smoke step: a clean checkout has no `build/` and `dart compile exe` does not create its output directory, so
  the compile step died with `Error: AOT compilation failed / PathNotFoundException: Cannot open file, path =
  '…\build\promptite.exe'` (exit 254). It only ever passed on this machine because a stale `build/` was sitting
  there. The step now creates the directory first, and `README.md` — which made the same "one command from a clean
  checkout" claim — shows `mkdir -p build` before the compile. Both jobs are green from `4d2596d` on.
- `bin/promptite.dart` — the `--script` -> `--strict` typo repair mangled an attached value. `--script=true` was
  rewritten to `--strict=true`, which `args` rejects with `FormatException: Flag option "--strict" should not be
  given a value`, and `--script:true` became `--strict:true`, which `args` silently drops (`:` is not a value
  separator for long options), so the repair warned and then did nothing. The value now selects the flag itself
  (`--script=true` -> `--strict`, `--script=false` -> `--no-strict`, either separator), and a non-boolean value
  exits 1 naming the accepted forms instead of a `FormatException`.
- `bin/promptite.dart` — the `--script` -> `--strict` typo repair was invisible to anyone reading the docs;
  it is now stated in the `-h` usage and in `README.md`.

### Decisions

- Divergences from the dart-flutter-bible are recorded in `BACKLOG.md` for later review and are **not**
  auto-fixed: a deviation marks a spot where the code and the bible disagree, and either side may be wrong.
- `BACKLOG.md` holds open/pending items only; anything settled moves here.
- The package's error style is FP-style tuples (`Either<Failure, T>`) converted to exit codes and stderr text
  at the CLI ring in `bin/promptite.dart`. The declaration is still missing from the barrel doc comment, the
  README and `AGENTS.md`; that is logged as a deviation rather than changed in this pass.
- `dart analyze --fatal-infos --fatal-warnings` and `dart test` are green, and CI now runs the gate on every
  pull request. The bible's full gate is still **not** met: there is no `dart_arch_test` boundary gate and no
  `examples/`, and `AGENTS.md` — which §1 expects — does not exist.
- The Windows build is verified by **compiling and running the binary**, not by `dart run`. `build/` is
  gitignored, so a committed artifact is impossible; the `windows-latest` CI lane invoking `dart compile exe`
  and then the README's three invocations against the `.exe` is what makes the Windows target machine-checked.
  A stale local `build/promptite.exe` will happily report old behaviour — rebuild after any source change.
- `dart pub publish --dry-run` must be run from a **committed** tree. With uncommitted edits it exits 65 on
  "N checked-in files are modified in git", which is indistinguishable from a real packaging failure and was
  mistaken for one in the 2026-09-25 audit unless read closely.
- The `--script` repair maps an attached value onto the *flag* rather than passing the value through, because
  `args` flags take no value at all; `:` is accepted next to `=` for the repaired form because users write it and
  the pre-existing code already claimed to handle it (silently, and wrongly).
- An attempt to add `AGENTS.md` on 2026-09-26 was refused by the writing agent's guardrail (protected
  agent-instruction file, no operator approval) and deliberately not retried through another path. The item
  stays open in `BACKLOG.md`; the deviation list there remains the only record until an operator approves it.

### Notes

- GitHub Actions, 2026-09-26: the runs on `5b7abf1` and on `913d24a` were **red** — `verify` green, `windows` red at
  "Compile the Windows binary" (`Smoke-test the binary` skipped). The run on `4d2596d` is green on both jobs, with
  the windows lane's compile and smoke steps completing for the first time.
- GitHub Actions, 2026-09-26: run `36266611738` on `main` @ `2e913ea` is green on **both** jobs, and its `windows`
  job is `tool/windows_smoke.sh` — the 26 checks in that script (clean-tree build, the README invocations, the
  stdout/stderr split, the exit codes, the banner, LF-only output, the `--script` repair, and a run from a foreign
  directory with the Dart SDK off `PATH`) are therefore machine-checked on every push, not only run by hand.
- Windows TEST + BUILD run, 2026-09-26, Dart 3.13.1 (stable) windows_x64, package version 1.0.0, `main` @
  `d7813c1`, measured in a **clean checkout of that commit** (a fresh `git worktree`, not the working tree): `dart
  pub get` OK (21 packages have newer versions incompatible with constraints); `dart format --output=none
  --set-exit-if-changed .` 6 files, 0 changed, exit 0; `dart analyze --fatal-infos --fatal-warnings` "No issues
  found!", exit 0; `dart test` 18/18, "All tests passed!", exit 0 (3 in `test/promptite_test.dart`, 15 end-to-end
  cases in `test/cli_test.dart` which compile the binary themselves); `dart pub publish --dry-run` "Package has 0
  warnings", exit 0; `dart compile exe bin/promptite.dart -o build/promptite.exe` produced a `PE32+ executable for
  MS Windows 10.00 (console), x86-64` (6,324,224 bytes) and that artifact, run against all three `README.md`
  invocations, printed the expected prompt with exit 0 — exit 1 with a usage block when `--task` is missing, and
  the same output from a foreign working directory with the Dart SDK off `PATH`. Every tracked file is LF-only
  (0 CRLF across 15 tracked files). The one defect this pass found in the build lane is fixed in `4d2596d`: the
  `windows` CI job could never compile on a clean checkout (no `build/` directory, which `dart compile exe` does not
  create), so the run on `4d2596d` — not this one — is what first exercised the compiled artifact machine-side.
- Windows build + test run, 2026-09-26, `main` @ `5b7abf1` plus the new smoke lane, all of it with `build/` absent:
  `dart format --output=none --set-exit-if-changed .` 8 files, 0 changed, exit 0; `dart analyze --fatal-infos
  --fatal-warnings` "No issues found!", exit 0; `dart test` **34/34**, "All tests passed!", exit 0 (10 in
  `test/promptite_test.dart`, 9 in `test/cli_text_test.dart`, 15 end-to-end cases in `test/cli_test.dart` which
  compile the binary themselves); `dart pub publish --dry-run` "Package has 0 warnings", exit 0 from a committed
  tree; `dart compile exe bin/promptite.dart -o build/promptite.exe` produced a `PE32+ executable for MS
  Windows 10.00 (console), x86-64` (6.0 MB), exit 0; and `bash tool/windows_smoke.sh` — which rebuilds that
  artifact from a tree with no `build/` and is now the whole `windows` CI job — reports **0 failure(s)** across 26
  checks, exit 0. Every tracked file is LF-only.
- Windows build + audit run, 2026-09-26, Dart 3.13.1 (stable) windows_x64, package version 1.0.0, `main` @
  `ee164ad`: `dart pub get` OK (21 packages have newer versions incompatible with constraints);
  `dart format --output=none --set-exit-if-changed .` 5 files, 0 changed, exit 0;
  `dart analyze --fatal-infos --fatal-warnings` "No issues found!", exit 0; `dart test` 3/3, "All tests
  passed!", exit 0; `dart compile exe bin/promptite.dart -o build/promptite.exe` produced a
  `PE32+ executable for MS Windows 10.00 (console), x86-64` (6.0 MB), exit 0, and that binary run against all
  three `README.md` invocations printed the expected prompt with exit 0 — and exit 1 with a usage block when
  `--task` is missing. `dart pub publish --dry-run` reaches "Package has 0 warnings" and **exit 0** from a
  committed tree; measured from the clean tree at `ee164ad`, not before the commit — an uncommitted tree makes
  the same command exit 65 on "checked-in files are modified in git".
- The 2026-09-25 audit note below is superseded where it disagrees: the publish dry run is clean, CI exists,
  and the `executable:` key is fixed. Its "no CI / exit 65" reading was correct for the tree it measured.

- Audit run on the Windows lane, 2026-09-25, Dart 3.13.1 (stable) windows_x64, package version 1.0.0 at
  `main` @ `494a299`: `dart pub get` OK (21 packages have newer versions incompatible with constraints);
  `dart format --output=none --set-exit-if-changed .` 5 files, 0 changed, exit 0;
  `dart analyze --fatal-infos --fatal-warnings` "No issues found!", exit 0; `dart test` 3/3,
  "All tests passed!", exit 0; `dart pub publish --dry-run` **exit 65**, "Package has 1 warning"
  (`"executable" is not a key recognized by pub - did you mean "executables"?`). No source file changed in
  this pass; every tracked file is LF-only.

## [2026-09-26]

### Added

- Windows build + CI lane: the `promptite.exe` release artifact (compiled with `dart compile exe`) is gated by the
  34-test `dart test` suite and exercised end to end by the W1 `windows` CI lane (`tool/windows_smoke.sh`) on
  `windows-latest`. It is green on `main` @ `2e913ea` (Actions run `36266611738`), the first commit whose `windows`
  job reached the smoke step.

## [1.0.0] - 2026-01-28

### Added

- Initial version: CLI prompt generator with `-t/--task`, `-f/--files`, `-c/--context`, `--strict` and
  `-h/--help`, assembling the prompt in `lib/src/promptite.dart` over a `Failure` hierarchy in
  `lib/src/failure.dart`.
- `test/promptite_test.dart` — 3 tests covering prompt assembly, strict truncation and the token estimate.

### Changed

- `bin/promptite.dart` reworked for argument parsing and error handling (`f3ce7ba`).

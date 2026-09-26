# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

### Changed

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

- `dart pub publish --dry-run` exited 65 on the unrecognized `executable:` pubspec key; with the correct
  `executables:` map the dry run reaches "Package has 0 warnings" and exit 0.
- `bin/promptite.dart` — `_showFriendlyError`'s `(error is Error || error is Exception)` ternary had two
  identical arms, so the type test could never change the output. Removed; newline flattening now happens on
  the `toString()` call itself.
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
  (0 CRLF across 15 tracked files). One caveat found while measuring, not fixed here: the `windows` CI lane runs
  `dart compile exe ... -o build/promptite.exe` on a clean checkout where `build/` does not exist, and the
  compiler does not create the output directory — it only ever passed locally because a stale `build/` was there.
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

## [1.0.0] - 2026-01-28

### Added

- Initial version: CLI prompt generator with `-t/--task`, `-f/--files`, `-c/--context`, `--strict` and
  `-h/--help`, assembling the prompt in `lib/src/promptite.dart` over a `Failure` hierarchy in
  `lib/src/failure.dart`.
- `test/promptite_test.dart` — 3 tests covering prompt assembly, strict truncation and the token estimate.

### Changed

- `bin/promptite.dart` reworked for argument parsing and error handling (`f3ce7ba`).

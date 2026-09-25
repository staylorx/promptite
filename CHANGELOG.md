# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `BACKLOG.md` recording open build/analysis issues and dart-flutter-bible deviations.
- Completed `BACKLOG.md` in the 2026-09-25 audit pass with the findings the first pass missed: the direct
  `package:promptite/src/...` imports in `bin/promptite.dart:5`, `test/promptite_test.dart:4` and
  `lib/src/promptite.dart:2`; the dead `_showFriendlyError` ternary and the undocumented
  `--script` -> `--strict` rewrite; the never-constructed `ConfigFailure`/`CliFailure`/`ApiFailure` leaves;
  the missing `examples/` for a pub.dev-targeted package; and the duplicated package description in
  `README.md:1` vs `pubspec.yaml:2`.

### Changed

- Normalized this file to the Keep a Changelog format (was a bare `## 1.0.0` heading with no date and no
  change-type headings).
- Corrected the `[1.0.0]` release date: it read `2026-09-24`, which is the audit date; both 1.0.0 commits are
  dated `2026-01-28` (`git log`: `71250a8`, `f3ce7ba`).
- Corrected a claim in `BACKLOG.md` that `Failure.message` is mutable; `lib/src/failure.dart:2` declares it
  `final`.

### Decisions

- Divergences from the dart-flutter-bible are recorded in `BACKLOG.md` for later review and are **not**
  auto-fixed: a deviation marks a spot where the code and the bible disagree, and either side may be wrong.
- `BACKLOG.md` holds open/pending items only; anything settled moves here.
- The package's error style is FP-style tuples (`Either<Failure, T>`) converted to exit codes and stderr text
  at the CLI ring in `bin/promptite.dart`. The declaration is still missing from the barrel doc comment, the
  README and `AGENTS.md`; that is logged as a deviation rather than changed in this pass.
- `dart analyze --fatal-infos --fatal-warnings` is green and `dart test` is green, but the bible's full gate is
  **not** met: `dart pub publish --dry-run` exits 65 on the unrecognized `executable:` pubspec key, and there
  is neither CI nor a `dart_arch_test` boundary gate.

### Notes

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

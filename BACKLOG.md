# BACKLOG

Open/pending items only. Decisions made are recorded in `CHANGELOG.md`.

Build/audit evidence (Dart SDK 3.13.1 stable windows_x64, Windows lane, `main` @ 494a299, re-run 2026-09-25):
`dart pub get` OK — 21 packages have newer versions incompatible with constraints;
`dart analyze --fatal-infos --fatal-warnings` -> "No issues found!" (exit 0);
`dart test` -> 3/3 passed, "All tests passed!" (exit 0);
`dart format --output=none --set-exit-if-changed .` -> 5 files, 0 changed (exit 0);
`dart pub publish --dry-run` -> **exit 65**, "Package has 1 warning" (below).
Also measured: no `TODO`/`FIXME` anywhere; **zero `///` doc comments** in all 5 `.dart` files; every tracked
file is LF-only (0 CRLF); no `.github/workflows`; `dart_arch_test` absent from `dev_dependencies`.

## Build / analysis problems

- [ ] `pubspec.yaml` — `executable:` is not a key recognized by pub; `dart pub publish --dry-run` warns
      "did you mean executables?". Correct form is `executables:` (a map, `promptite: promptite`). Without it
      the package ships no CLI executable.
- [ ] `analysis_options.yaml` — legacy `analyzer.strong-mode.implicit-casts/implicit-dynamic` are obsolete
      (Dart 3 replaced them with `language.strict-casts`/`strict-raw-types`, which are also already set);
      dead config, silently ignored by the analyzer.
- [ ] `analysis_options.yaml` — `prefer_const_constructors` is enabled as a linter rule AND set to `ignore`
      under `errors:`; contradictory, one of the two should go.
- [ ] No CI workflow — there is no `.github/workflows`; the bible (§2, §9 step 10) expects
      `dart analyze --fatal-infos --fatal-warnings` + `dart test` to run on every PR.
- [ ] No `AGENTS.md` — the bible (§1) expects a repo `AGENTS.md` recording that repo's deviations and local
      wiring.
- [ ] `bin/promptite.dart:106` — `_showFriendlyError` branches on `(error is Error || error is Exception)`
      but both arms evaluate to `error.toString()`, so the ternary is dead: the type test never changes the
      output.
- [ ] `bin/promptite.dart:74` — `_preprocessArguments` silently rewrites `--script` to `--strict` and warns on
      stderr; the correction map has exactly one entry and is documented nowhere (`README.md` and the `-h`
      usage both omit it), so the repair is invisible to anyone reading the docs.
- [ ] No `examples/` — `pubspec.yaml` targets pub.dev (no `publish_to: none`, `repository:` set) and the bible
      §2 makes a real, CI-tested `examples/` a package deliverable; there is none, and nothing exercises the
      three CLI invocations the README documents.
- [ ] `pubspec.yaml:2` and `README.md:1` describe the same package twice in different words, and both still
      call a released 1.0.0 tool a "sample command-line application" (bootstrap-template text); §1 D.R.Y.
      keeps one copy.

## Deviations from the dart-flutter-bible (docs/01–12)

Flagged for later review; not auto-fixed. The bible may itself be wrong on some of these.

- Deviation: `pubspec.yaml` — SDK constraint is `^3.10.0`; the bible §2 prescribes the literal
  `'>=3.10.0 <4.0.0'`. Semantically identical (`^3.10.0` == `>=3.10.0 <4.0.0`); the bible may be
  over-specifying exact string form.
- Deviation: `analysis_options.yaml` — `public_member_api_docs` is not enabled; the bible §2/§9 requires it ON
  (lint-enforced, part of the clean gate).
- Deviation: `analysis_options.yaml` — `todo: ignore`; the bible §2 maps `todo: error` so a TODO fails the
  build. No TODOs exist in the tree today, but the config contradicts doctrine.
- Deviation: `analysis_options.yaml` — `prefer_const_constructors` is disabled under `errors:`; the bible §2
  says never disable a rule in `analysis_options.yaml` (per-line ignores only).
- Deviation: repo layout — a single flat package (`bin/`, `lib/`, `test/`) with no pub workspace and no
  domain/usecases/datasource split; the bible §3 Topology A/B prescribes a workspace with `*_domain`,
  `*_usecases` and >=2 datasource adapters. Arguably overkill for a dependency-free CLI with no persistence.
- Deviation: `test/` — no `dart_arch_test` architecture/boundary test; the bible §2/§9 requires one running as
  part of `dart test`.
- Deviation: `test/promptite_test.dart` — uses `package:test` `expect()`; the bible §6 mandates `shouldly`
  (`x.should.be(...)`) and forbids mixing the two.
- Deviation: `test/promptite_test.dart` — test names are plain (`'includes task, files and context ...'`), not
  Given/When/Then; the bible §6 requires Given/When/Then names.
- Deviation: `test/promptite_test.dart` — only happy paths are covered; the bible §6 requires both Either
  sides. The `Left` paths (empty task/context, invalid file names) are untested.
- Deviation: `lib/src/failure.dart` — `abstract class Failure` is not `sealed` and its leaves are not
  `final`/`sealed`; the bible §4 requires a sealed per-layer hierarchy so a `switch` is exhaustive.
- Deviation: `lib/src/failure.dart` — failures are one flat set (Task/Context/Files/Config/Cli/Api) with no
  per-layer split; the bible §4 wants a domain vs datasource split with mapping at the repository.
- Deviation: `lib/src/failure.dart` — `Failure` declares `final String? message` (line 2: immutable, not
  mutable) with a non-const constructor and no `Equatable`/`props`; the bible §1/§4 require immutable value
  objects **with value equality**, so two `TaskFailure('Task is empty')` values are not `==` and cannot be
  asserted or matched by value.
- Deviation: `lib/src/failure.dart` — 7 classes in one file; the bible §3 requires one class per file.
- Deviation: `lib/src/promptite.dart` — `Either.tryCatch` wraps hand-written validation (`throw Exception(...)`)
  rather than a third-party call; the bible §4 restricts `tryCatch` to adapter boundaries wrapping the
  third-party call itself ("a line, not a zone").
- Deviation: `lib/src/promptite.dart` — `generateTightPrompt` throws via
  `.match((l) => throw Exception(...))`; the bible §1/§4 keep exceptions out of the core (`lib/`) — only the
  UI/CLI ring may throw. The CLI's error flow depends on that throw, so the seam is effectively exceptions but
  is never declared.
- Deviation: `lib/promptite.dart` — the barrel carries no doc comment declaring the package error style; the
  bible §4/§10 require the style named in the barrel, the README, and (on deviation) `AGENTS.md`.
- Deviation: `README.md` — does not state the package error style near the top; the bible §4 requires it.
- Deviation: `lib/src/promptite.dart` — public functions carry no `///` docs (1–2 lines, what+why); the bible
  §2 requires terse docs on every declaration and public member.
- Deviation: `lib/src/promptite.dart` — positional params `taskPrompt(String task, bool strict)`,
  `contextPrompt(String context, bool strict)`, `filesPrompt(List<String> fileList)`; the bible §2 requires
  named params (sole exceptions: a single positional `ref`/`message`).
- Deviation: `bin/promptite.dart` — `const String version = '1.0.0'` duplicates `pubspec.yaml`
  `version: 1.0.0`, a second source of truth; the bible §1 (D.R.Y.) wants exactly one.
- Deviation: `lib/src/promptite.dart` — `generateTightPromptEither` composes with nested `flatMap`; the bible
  §4 says prefer fpdart Do-notation for readability.
- Deviation: `lib/src/promptite.dart` — `estimateTokensEither` returns `Right(...)` unconditionally (an
  `Either` that can never be `Left`); the bible §4 uses the type only where the operation can fail.
- Deviation: `lib/src/promptite.dart:102` — `estimateTokens` then discards that Left with
  `getOrElse((_) => 0)`, so a genuine estimate of 0 tokens and a failed estimate are the same value; §4 keeps
  failure a value the caller can see.
- Deviation: `lib/src/failure.dart` — `ConfigFailure` (:18), `CliFailure` (:22) and `ApiFailure` (:26) are
  never constructed anywhere in the tree (grep finds only their declarations), so half the hierarchy is dead;
  §4's failure set is meant to be the reachable failure space.
- Deviation: `bin/promptite.dart:5` and `test/promptite_test.dart:4` — both import
  `package:promptite/src/promptite.dart` directly instead of the `package:promptite/promptite.dart` barrel
  that exists as the package's one public door (§2); `implementation_imports` stays silent because it only
  covers cross-package imports, so the barrel is decorative for in-repo callers.
- Deviation: `lib/src/promptite.dart:2` — a file under `src/` imports its own package barrel
  (`package:promptite/promptite.dart`) to reach `Failure`, reversing the §2/§3 direction in which the barrel
  re-exports `src/` while `src/` stays private.
- Deviation: `README.md:7-13` — carries three runnable example invocations plus an `Examples:` block; §2 homes
  example code in tests first and allows prose docs only a one-line command, and nothing tests these three.

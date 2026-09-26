# BACKLOG

Open/pending items only. Decisions made are recorded in `CHANGELOG.md`.

Build/audit evidence (Dart SDK 3.13.1 stable windows_x64, Windows lane, `main` @ `d7813c1`, re-run 2026-09-26,
measured in a clean checkout of that commit — full record in `CHANGELOG.md`):
`dart pub get` OK — 21 packages have newer versions incompatible with constraints;
`dart analyze --fatal-infos --fatal-warnings` -> "No issues found!" (exit 0);
`dart test` -> 18/18 passed, "All tests passed!" (exit 0) — 3 in `test/promptite_test.dart` plus 15 end-to-end
cases in `test/cli_test.dart`, which compile and run the binary itself;
`dart format --output=none --set-exit-if-changed .` -> 6 files, 0 changed (exit 0);
`dart pub publish --dry-run` -> **exit 0** from a committed tree, "Package has 0 warnings";
`dart compile exe bin/promptite.dart -o build/promptite.exe` -> `PE32+ executable for MS Windows 10.00
(console), x86-64`, 6,324,224 bytes, exit 0;
that binary run against all three `README.md` invocations -> the expected prompt on stdout, exit 0, and exit 1
for a missing `--task`; run from a foreign working directory with the Dart SDK off `PATH` -> the same prompt.
Also measured: no `TODO`/`FIXME` anywhere; `///` doc comments in 2 of the 6 tracked `.dart` files
(`bin/promptite.dart`, `test/cli_test.dart`); every tracked file is LF-only (0 CRLF across 15 tracked files);
`dart_arch_test` absent from `dev_dependencies`.
GitHub Actions on `main` @ `4d2596d`: `verify` **green** and the `windows` lane **green** (compile + README smoke
test) — the first run in which that lane compiled at all; the runs on `5b7abf1` and `913d24a` were red there for
the missing `build/` directory, see `CHANGELOG.md`.

## Open build / analysis problems

- [ ] No `examples/` — `pubspec.yaml` targets pub.dev (no `publish_to: none`, `repository:` set) and the bible
      §2 makes a real, CI-tested `examples/` a package deliverable; there is none. The CLI-coverage half of this
      item was closed on 2026-09-26 by `test/cli_test.dart` (15 cases, commit `d7813c1`): `-t`/`-f`/`-c`/`--strict`
      parsing, the usage banner on no args and `-h`, exit 1 on a missing `--task`, exit 1 on an unknown option,
      the `--script` repair — including the `=value`/`:value` forms, which writing those tests **fixed**, see
      `CHANGELOG.md` — plus UTF-8 passthrough, LF-only output and a run with the Dart SDK off `PATH`, all under
      `dart test` against the compiled binary.
- [ ] No `AGENTS.md` — the bible (§1) expects a repo `AGENTS.md` recording that repo's deviations and local
      wiring. A write attempted on 2026-09-26 was refused by the writing agent's own guardrail (protected
      agent-instruction file; operator approval did not arrive) and was deliberately not retried, so no
      `AGENTS.md` exists and this file's deviation list remains the only record. Needs an operator-approved
      write.

## Deviations from the dart-flutter-bible (docs/01–12)

Flagged for later review; not auto-fixed. The bible may itself be wrong on some of these.

- Deviation: `pubspec.yaml` — SDK constraint is `^3.10.0`; the bible §2 prescribes the literal
  `'>=3.10.0 <4.0.0'`. Semantically identical (`^3.10.0` == `>=3.10.0 <4.0.0`); the bible may be
  over-specifying exact string form.
- Deviation: `analysis_options.yaml` — `public_member_api_docs` is not enabled; the bible §2/§9 requires it ON
  (lint-enforced, part of the clean gate).
- Deviation: `analysis_options.yaml` — `todo: ignore`; the bible §2 maps `todo: error` so a TODO fails the
  build. No TODOs exist in the tree today, but the config contradicts doctrine.
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
- Deviation: `README.md` — carries three runnable example invocations plus an `Examples:` block; §2 homes
  example code in tests first and allows prose docs only a one-line command. Kept: those three flags are the
  tool's whole interface, and the Windows CI lane now executes them against the compiled binary, so they
  cannot rot silently.
- Deviation: `README.md` — the "Building on Windows" section adds two more runnable commands in a bash fence
  (`dart pub get`, `dart compile exe ...`). Kept on purpose: the Windows native build is the deliverable and
  must be reproducible from the README, and §2's "smallest exception" (a one-line command) cannot express a
  two-step build plus a verify step.

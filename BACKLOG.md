# BACKLOG

Open/pending items only. Decisions made are recorded in `CHANGELOG.md`.

## Deviations from the dart-flutter-bible (docs/01–12)

Flagged for later review; not auto-fixed. The bible may itself be wrong on some of these. Resolved items are
recorded (with the decision) in `CHANGELOG.md`, not here.

- Deviation: repo layout — a single flat package (`bin/`, `lib/`, `test/`) with no pub workspace and no
  domain/usecases/datasource split; the bible §3 Topology A/B prescribes a workspace with `*_domain`,
  `*_usecases` and >=2 datasource adapters. Kept: overkill for a dependency-free CLI with no persistence.
- Deviation: `test/` — no `dart_arch_test` architecture/boundary test; the bible §2/§9 requires one running as
  part of `dart test`. Kept: with a single flat package there are no cross-package boundaries or layers for an
  arch test to enforce.
- Deviation: `test/promptite_test.dart` — uses `package:test` `expect()`; the bible §6 mandates `shouldly`
  (`x.should.be(...)`). Kept: switching the assertion library adds a dev dependency and churn with no
  functional difference for this package.
- Deviation: `lib/src/failure.dart` — failures are one flat set with no per-layer split; the bible §4 wants a
  domain vs datasource split with mapping at the repository. Kept: there is no repository/datasource layer in
  this package to split between; the hierarchy is sealed so a `switch` is exhaustive.
- Deviation: `README.md` — carries three runnable example invocations plus an `Examples:` block; §2 homes
  example code in tests first. Kept: those three flags are the tool's whole interface, and the Windows CI
  lane executes them against the compiled binary, so they cannot rot silently.
- Deviation: `README.md` — the "Building on Windows" section adds two more runnable commands in a bash fence
  (`dart pub get`, `dart compile exe ...`). Kept on purpose: the Windows native build is the deliverable and
  must be reproducible from the README, and §2's "smallest exception" (a one-line command) cannot express a
  two-step build plus a verify step.

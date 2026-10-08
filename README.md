> **Error style:** the library returns fpdart `Either<Failure, String>` —
> failures are values, in `lib/src/failure.dart`. The one throwing function is
> `generateTightPrompt`, the seam the CLI sits on; nothing else throws.

## Usage

Run the tool with `dart run` from the project root — or use the compiled Windows
binary, see [Building on Windows](#building-on-windows). The tool supports `-t/--task`, `-f/--files`, `-c/--context`, `--strict`, and `-h/--help`.

`--script` is accepted as a repaired typo for `--strict`: a warning goes to
stderr and `--strict` is applied. `--script=false` becomes `--no-strict`; a
non-boolean value (e.g. `--script=yes`) is refused with exit 1 rather than
guessed at.

Examples:

```bash
dart run bin/promptite.dart -t "Refactor auth" -f "lib/auth.dart,lib/util.dart"
dart run bin/promptite.dart -t "Add tests" -c "Focus on login flow" --strict
dart run bin/promptite.dart -h
```

When run with no arguments or with `-h/--help`, the program prints usage and exits.
The banner names the copy of the tool you actually ran, so the compiled binary
prints `promptite.exe <flags>` and spells its examples as `promptite.exe` lines —
it never tells a Windows user to reach for a Dart SDK they may not have.

## Building on Windows

`pubspec.yaml` declares `executables:`, so a native Windows console binary is
three commands from a clean checkout:

```bash
dart pub get
mkdir -p build   # a clean checkout has no build/, and `dart compile exe` will not create it
dart compile exe bin/promptite.dart -o build/promptite.exe
```

`build/` is gitignored, so a fresh checkout has no such directory — and
`dart compile exe` does **not** create its output directory. Without the `mkdir`
the compile fails with `PathNotFoundException` on `build\promptite.exe`, which is
how CI's `windows-latest` lane went red before that line was added. `build/` being
gitignored also cuts the other way: a stale `.exe` will happily report old
behaviour, so rebuild after any source change.

Validate the artifact with the same lane CI runs:

```bash
bash tool/windows_smoke.sh
```

It rebuilds from a clean tree with the commands above and then exercises the
binary: the three invocations in this README, the stdout/stderr split, the exit
codes, the `--script` repair, the banner, LF-only output, non-ASCII arguments, and
a run from a foreign directory with the Dart SDK off `PATH`. The `windows-latest`
CI lane *is* that script, so the Windows build is machine-verified rather than
assumed.

## License

This project is licensed under the MIT License — see the `LICENSE` file for details.

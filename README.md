## Usage

Run the tool with `dart run` from the project root — or use the compiled Windows
binary, see [Building on Windows](#building-on-windows). The tool supports `-t/--task`, `-f/--files`, `-c/--context`, `--strict`, and `-h/--help`.

`--script` is accepted as a repaired typo for `--strict`: a warning goes to
stderr and `--strict` is applied.

Examples:

```bash
dart run bin/promptite.dart -t "Refactor auth" -f "lib/auth.dart,lib/util.dart"
dart run bin/promptite.dart -t "Add tests" -c "Focus on login flow" --strict
dart run bin/promptite.dart -h
```

When run with no arguments or with `-h/--help`, the program prints usage and exits.

## Building on Windows

`pubspec.yaml` declares `executables:`, so a native Windows console binary is two
commands from a clean checkout:

```bash
dart pub get
mkdir -p build   # a clean checkout has no build/, and `dart compile exe` will not create it
dart compile exe bin/promptite.dart -o build/promptite.exe
```

`build/` is gitignored — rebuild after any source change, a stale `.exe` will
happily report old behaviour. CI's `windows-latest` lane runs exactly those
commands and then executes the three invocations above against the binary, so the
Windows build is machine-verified rather than assumed. Check it locally with:

```bash
./build/promptite.exe -t "Refactor auth" -f "lib/auth.dart,lib/util.dart"
```

## License

This project is licensed under the MIT License — see the `LICENSE` file for details.

A sample command-line application providing basic argument parsing with an entrypoint in `bin/`.

## Usage

Run the tool with `dart run` from the project root. The tool supports `-t/--task`, `-f/--files`, `-c/--context`, `--strict`, and `-h/--help`.

Examples:

```bash
dart run bin/promptite.dart -t "Refactor auth" -f "lib/auth.dart,lib/util.dart"
dart run bin/promptite.dart -t "Add tests" -c "Focus on login flow" --strict
dart run bin/promptite.dart -h
```

When run with no arguments or with `-h/--help`, the program prints usage and exits.

## License

This project is licensed under the MIT License — see the `LICENSE` file for details.

// A runnable example for the promptite package and its CLI.
//
// Run this library example from the package root:
//
//   dart run example/example.dart
//
// The same prompt is produced by the CLI, either from source or the compiled
// Windows binary:
//
//   dart run bin/promptite.dart -t "Refactor auth" \
//       -f "lib/auth.dart,lib/session.dart" \
//       -c "Keep the public API unchanged; add tests." --strict
//
//   dart compile exe bin/promptite.dart -o build/promptite.exe
//   build/promptite.exe -t "Refactor auth" -f "lib/auth.dart,lib/session.dart"
//
// The library returns fpdart `Either<Failure, String>`. `generateTightPrompt`
// is the throwing convenience form the CLI sits on; the Either form at the
// bottom shows failure handled as a value instead of a thrown exception.
import 'dart:io';

import 'package:promptite/promptite.dart';

void main() {
  final prompt = generateTightPrompt(
    task: 'Refactor auth',
    files: ['lib/auth.dart', 'lib/session.dart'],
    context: 'Keep the public API unchanged; add tests.',
    strict: true,
  );

  stdout.writeln('Assembled prompt:');
  stdout.writeln(prompt);
  stdout.writeln('Token estimate: ~${estimateTokens(prompt)} tokens');

  // The Either form makes a failure a value the caller can see and handle:
  // an empty task is a `Left(TaskFailure('Task is empty'))`, not a throw.
  generateTightPromptEither(task: '', strict: false).match(
    (failure) => stdout.writeln('Handled a failure: ${failure.message}'),
    (ok) => stdout.writeln('Unexpected success: $ok'),
  );
}

import 'package:fpdart/fpdart.dart';
import 'package:promptite/src/failure.dart';

/// Assembles a token-lean prompt from [task], optional [files] and [context],
/// and returns it as a `Right`, or the failure as a `Left` when any section is
/// invalid.
///
/// The composition uses fpdart Do-notation so each step's `Left` short-circuits
/// the rest; failures are returned as values, never thrown (see
/// [generateTightPrompt] for the throwing form the CLI uses).
Either<Failure, String> generateTightPromptEither({
  required String task,
  List<String>? files,
  String? context,
  bool? strict,
}) {
  return Either.Do(($) {
    final t = $(taskPrompt(task: task, strict: strict ?? false));
    final tf = (files?.isNotEmpty ?? false)
        ? '$t\n${$(filesPrompt(fileList: files!))}'
        : t;
    final tfc = '$tf\n${$(constraintsPrompt())}';
    final tfcx = (context?.isNotEmpty ?? false)
        ? '$tfc\n${$(contextPrompt(context: context!, strict: strict ?? false))}'
        : tfc;
    return '$tfcx\n${$(instructionsPrompt())}'.trim();
  });
}

/// The throwing form of [generateTightPromptEither], used by the CLI seam.
///
/// The functional core returns failures as `Either` values; this convenience
/// form turns a `Left` into an `Exception` for callers such as the CLI that
/// cannot handle an `Either`. The message names the failure once — callers that
/// print `toString()` already get an `Exception: ` prefix, so the message must
/// not carry a second one.
String generateTightPrompt({
  required String task,
  List<String>? files,
  String? context,
  bool strict = false,
}) {
  return generateTightPromptEither(
    task: task,
    files: files,
    context: context,
    strict: strict,
  ).match(
    (l) => throw Exception('Failed to generate prompt: ${l.message ?? l}'),
    (r) => r,
  );
}

/// Builds the `<task>` section, truncating to the first 5 words in [strict]
/// mode.
///
/// Returns `Left(TaskFailure)` when [task] is blank.
Either<Failure, String> taskPrompt({
  required String task,
  bool strict = false,
}) {
  if (task.trim().isEmpty) {
    return const Left(TaskFailure('Task is empty'));
  }
  final content = strict ? task.split(' ').take(5).join(' ') : task;
  return Right('<task>$content</task>');
}

/// The fixed `<constraints>` block every prompt carries: only listed files, no
/// new dependencies, minimal changes, a test included.
Either<Failure, String> constraintsPrompt() {
  return const Right(
    '<constraints>\n'
    '  - Use only listed files\n'
    '  - No new dependencies\n'
    '  - Minimal changes\n'
    '  - Test included\n'
    '</constraints>',
  );
}

/// Builds the `<context>` section, truncating to the first 8 words in [strict]
/// mode.
///
/// Returns `Left(ContextFailure)` when [context] is blank.
Either<Failure, String> contextPrompt({
  required String context,
  bool strict = false,
}) {
  if (context.trim().isEmpty) {
    return const Left(ContextFailure('Context is empty'));
  }
  final content = strict ? context.split(' ').take(8).join(' ') : context;
  return Right('<context>$content</context>');
}

/// The fixed `<instructions>` block every prompt carries: code plus a one-line
/// explanation, no thinking aloud, no repeated context.
Either<Failure, String> instructionsPrompt() {
  return const Right(
    '<instructions>\n'
    '  - Respond with ONLY code + 1-line explanation\n'
    '  - No thinking aloud\n'
    '  - No repeated context\n'
    '</instructions>',
  );
}

/// Builds the `<files>` section, tagging each file with `@`.
///
/// Returns `Left(FilesFailure)` when [fileList] is empty or a name contains an
/// angle bracket (which would corrupt the surrounding XML tags).
Either<Failure, String> filesPrompt({required List<String> fileList}) {
  if (fileList.isEmpty) {
    return const Left(FilesFailure('File list is empty'));
  }
  for (final file in fileList) {
    if (file.contains('<') || file.contains('>')) {
      return const Left(FilesFailure('Invalid characters in file names'));
    }
  }
  return Right('<files>${fileList.map((f) => '@$f').join(', ')}</files>');
}

/// A rough token estimate for [prompt]: ~1 token per 4 characters plus a fixed
/// XML-tag overhead of 20.
///
/// This is a pure heuristic and never fails — it returns an `int`, not an
/// `Either`, so a caller cannot confuse an estimate of 0 with a failure.
int estimateTokens(String prompt) => (prompt.length / 4).ceil() + 20;

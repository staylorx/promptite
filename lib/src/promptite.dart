import 'package:fpdart/fpdart.dart';
import 'package:promptite/promptite.dart';

Either<Failure, String> generateTightPromptEither({
  required String task,
  List<String>? files,
  String? context,
  bool? strict,
}) {
  return taskPrompt(task, strict ?? false)
      .flatMap(
        (t) => (files?.isNotEmpty ?? false)
            ? filesPrompt(files!).map((f) => '$t\n$f')
            : Right<Failure, String>(t),
      )
      .flatMap((tf) => constraintsPrompt().map((c) => '$tf\n$c'))
      .flatMap(
        (tfc) => (context?.isNotEmpty ?? false)
            ? contextPrompt(context!, strict ?? false).map((c) => '$tfc\n$c')
            : Right<Failure, String>(tfc),
      )
      .flatMap((tfcx) => instructionsPrompt().map((i) => '$tfcx\n$i'))
      .map((s) => s.trim());
}

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

Either<Failure, String> taskPrompt(String task, bool strict) {
  return Either<Failure, String>.tryCatch(() {
    if (task.trim().isEmpty) throw Exception('Task is empty');
    final content = strict ? task.split(' ').take(5).join(' ') : task;
    return '<task>$content</task>';
  }, (e, _) => TaskFailure(e.toString()));
}

Either<Failure, String> constraintsPrompt() {
  return Right(
    '<constraints>\n'
    '  - Use only listed files\n'
    '  - No new dependencies\n'
    '  - Minimal changes\n'
    '  - Test included\n'
    '</constraints>',
  );
}

Either<Failure, String> contextPrompt(String context, bool strict) {
  return Either<Failure, String>.tryCatch(() {
    if (context.trim().isEmpty) throw Exception('Context is empty');
    final content = strict ? context.split(' ').take(8).join(' ') : context;
    return '<context>$content</context>';
  }, (e, _) => ContextFailure(e.toString()));
}

Either<Failure, String> instructionsPrompt() {
  return Right(
    '<instructions>\n'
    '  - Respond with ONLY code + 1-line explanation\n'
    '  - No thinking aloud\n'
    '  - No repeated context\n'
    '</instructions>',
  );
}

Either<Failure, String> filesPrompt(List<String> fileList) {
  return Either<Failure, List<String>>.tryCatch(
    () {
      if (fileList.isEmpty) {
        throw Exception('File list is empty');
      }
      for (final file in fileList) {
        if (file.contains('<') || file.contains('>')) {
          throw Exception('Invalid characters in file names');
        }
      }
      return fileList;
    },
    (error, stackTrace) => FilesFailure(error.toString()),
  ).map((files) => '<files>${files.map((f) => '@$f').join(', ')}</files>');
}

Either<Failure, int> estimateTokensEither(String prompt) {
  // Rough heuristic: 1 token ≈ 4 chars for English + XML overhead
  return Right((prompt.length / 4).ceil() + 20); // +20 for XML tag overhead
}

int estimateTokens(String prompt) {
  return estimateTokensEither(prompt).getOrElse((_) => 0);
}

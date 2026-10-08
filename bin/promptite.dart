import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:promptite/promptite.dart';

/// The CLI entrypoint: parses flags, builds the prompt via the library, writes
/// it to stdout with a token estimate, and exits. On a failure it reports one
/// line to stderr and exits 1; with no args or `-h` it prints usage and exits
/// 0.
void main(List<String> arguments) {
  runZonedGuarded(
    () async {
      final parser = ArgParser()
        ..addOption('task', abbr: 't', help: 'Main task description (required)')
        ..addOption(
          'files',
          abbr: 'f',
          help: 'Comma-separated files to include',
        )
        ..addOption('context', abbr: 'c', help: 'Additional context/notes')
        ..addFlag(
          'strict',
          abbr: 's',
          defaultsTo: false,
          help: 'Ultra-tight mode (minimal words)',
        )
        ..addFlag(
          'help',
          abbr: 'h',
          negatable: false,
          help: 'Show this help and exit',
        );
      final processedArgs = _preprocessArguments(arguments);
      final results = parser.parse(processedArgs);

      if (processedArgs.isEmpty || (results['help'] as bool)) {
        printUsage(parser);
        exit(0);
      }

      final task = (results['task'] as String?) ?? '';
      final files = (((results['files'] as String?) ?? ''))
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();
      final context = (results['context'] as String?) ?? '';
      final strict = results['strict'] as bool;

      if (task.isEmpty) {
        stderr.writeln('Error: --task is required.');
        printUsage(parser);
        exit(1);
      }

      final prompt = generateTightPrompt(
        task: task,
        files: files.isEmpty ? null : files,
        context: context.isEmpty ? null : context,
        strict: strict ? true : false,
      );
      stdout.writeln(prompt);
      stdout.writeln(
        '\n--- Token estimate: ~${estimateTokens(prompt)} tokens ---',
      );
    },
    (error, stack) {
      _showFriendlyError(error, stack);
    },
  );
}

List<String> _preprocessArguments(List<String> args) {
  if (args.isEmpty) return args;
  final typoMap = <String, String>{'--script': '--strict'};
  final out = <String>[];
  for (final arg in args) {
    var replacedArg = arg;
    for (final bad in typoMap.keys) {
      final good = typoMap[bad]!;
      if (arg == bad) {
        stderr.writeln(
          "Warning: '$arg' looks like a typo. Using '$good' instead.",
        );
        replacedArg = good;
        break;
      }
      if (arg.startsWith('$bad=') || arg.startsWith('$bad:')) {
        replacedArg = _repairFlagWithValue(
          bad,
          good,
          arg.substring(bad.length + 1),
        );
        break;
      }
    }
    out.add(replacedArg);
  }
  return out;
}

/// Repairs `--script=<value>` (or `--script:<value>`) into the flag form that
/// actually works.
///
/// `--script` is a repaired typo for the `--strict` flag, so an attached value
/// cannot be passed through verbatim: `args` rejects `--strict=true` as a flag
/// that "should not be given a value", and it silently drops `--strict:true`
/// (`:` is not a value separator for long options), which turns the typo repair
/// into a no-op. The boolean value therefore selects the flag itself —
/// `--strict` or `--no-strict`.
String _repairFlagWithValue(String bad, String good, String value) {
  if (value == 'true' || value == 'false') {
    final repaired = value == 'true' ? good : '--no-strict';
    stderr.writeln(
      "Warning: '$bad' looks like a typo. Using '$repaired' instead.",
    );
    return repaired;
  }
  stderr.writeln(
    "Error: '$bad' takes no value (got '$value'). Use '$good', '$good=true' "
    "or '$good=false'.",
  );
  exit(1);
}

void _showFriendlyError(Object error, StackTrace? stack) {
  final isDebug = Platform.environment['DEBUG'] == '1';
  if (isDebug) {
    stderr.writeln(error);
    if (stack != null) stderr.writeln(stack);
  } else {
    // Every throwable's message is what the user is shown; `userFacingMessage`
    // owns the rendering rules (one line, no doubled type prefix).
    stderr.writeln('Error: ${userFacingMessage(error)}');
    stderr.writeln('Run with DEBUG=1 to see the full stack trace.');
  }
  exit(1);
}

/// Prints the usage banner, naming the copy of the tool the user actually ran —
/// a compiled `promptite.exe` must not be told to reach for `dart run`.
void printUsage(ArgParser argParser) {
  stdout.writeln(
    renderUsage(
      version: promptiteVersion,
      invocation: invocationLabel(
        scriptPath: Platform.script.toFilePath(),
        executablePath: Platform.resolvedExecutable,
        cwdPath: Directory.current.uri.toFilePath(),
      ),
      parserUsage: argParser.usage,
    ),
  );
}

import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:promptite/src/promptite.dart';

const String version = '1.0.0';

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
  for (var arg in args) {
    var replacedArg = arg;
    for (final bad in typoMap.keys) {
      if (arg == bad) {
        stderr.writeln(
          "Warning: '$arg' looks like a typo. Using '${typoMap[bad]}' instead.",
        );
        replacedArg = typoMap[bad]!;
        break;
      }
      if (arg.startsWith('$bad=') || arg.startsWith('$bad:')) {
        final suffix = arg.substring(bad.length);
        stderr.writeln(
          "Warning: '$bad' looks like a typo. Using '${typoMap[bad]}$suffix' instead.",
        );
        replacedArg = typoMap[bad]! + suffix;
        break;
      }
    }
    out.add(replacedArg);
  }
  return out;
}

void _showFriendlyError(Object error, StackTrace? stack) {
  final isDebug = Platform.environment['DEBUG'] == '1';
  if (isDebug) {
    stderr.writeln(error);
    if (stack != null) stderr.writeln(stack);
  } else {
    // Every throwable's `toString()` is the message we show; there is no
    // reason to branch on the type. Newlines are flattened so the one-line
    // error stays readable in a terminal.
    final msg = error.toString().replaceAll(RegExp(r"\n"), ' ');
    stderr.writeln('Error: $msg');
    stderr.writeln('Run with DEBUG=1 to see the full stack trace.');
  }
  exit(1);
}

void printUsage(ArgParser argParser) {
  stdout.writeln('promptite version $version');
  stdout.writeln('Usage: dart run bin/promptite.dart <flags>');
  stdout.writeln('');
  stdout.writeln('Note: -t / --task is required.');
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln(
    '  dart run bin/promptite.dart -t "Refactor auth" -f "lib/auth.dart,lib/util.dart"',
  );
  stdout.writeln(
    '  dart run bin/promptite.dart -t "Add tests" -c "Focus on login flow" --strict',
  );
  stdout.writeln('');
  stdout.writeln(
    "Note: '--script' is accepted as a repaired typo for '--strict' (a warning "
    'is printed to stderr).',
  );
  stdout.writeln('');
  stdout.writeln(argParser.usage);
}

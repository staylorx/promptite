import 'dart:io';

import 'package:args/args.dart';
import 'package:promptite/src/promptite.dart';

const String version = '1.0.0';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('task', abbr: 't', help: 'Main task description (required)')
    ..addOption('files', abbr: 'f', help: 'Comma-separated files to include')
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

  final results = parser.parse(arguments);

  if (arguments.isEmpty || (results['help'] as bool)) {
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
  stdout.writeln('\n--- Token estimate: ~${estimateTokens(prompt)} tokens ---');
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
  stdout.writeln(argParser.usage);
}

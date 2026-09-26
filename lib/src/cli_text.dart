/// Text the CLI ring prints: the usage banner and the one-line error report.
///
/// Nothing here imports `dart:io`, so the rendering rules are unit-testable
/// without a process — `bin/promptite.dart` supplies the platform values.
library;

/// The command a user should type to run this copy of the tool.
///
/// A binary built with `dart compile exe` resolves its own script to itself, so
/// it is named directly; under `dart run` the script is the `.dart` entrypoint
/// and the invocation is spelled as a `dart run` command. Getting this wrong
/// tells the user of the Windows binary to reach for an SDK they may not have.
String invocationLabel({
  required String scriptPath,
  required String executablePath,
  required String cwdPath,
}) {
  final script = _lastSegment(scriptPath);
  final executable = _lastSegment(executablePath);
  if (script == executable) return executable;

  final cwd = _trimTrailingSeparators(cwdPath);
  final target = cwd.isNotEmpty && scriptPath.startsWith(cwd)
      ? scriptPath.substring(cwd.length)
      : scriptPath;
  // Forward slashes on every platform: the banner is a command a human copies,
  // and the repo's own docs spell the entrypoint `bin/promptite.dart`.
  final command = _trimLeadingSeparators(target).replaceAll(r'\', '/');
  return 'dart run $command';
}

/// The whole usage banner, as one string the CLI prints with a trailing newline.
String renderUsage({
  required String version,
  required String invocation,
  required String parserUsage,
}) {
  return [
    'promptite version $version',
    'Usage: $invocation <flags>',
    '',
    'Note: -t / --task is required.',
    '',
    'Examples:',
    '  $invocation -t "Refactor auth" -f "lib/auth.dart,lib/util.dart"',
    '  $invocation -t "Add tests" -c "Focus on login flow" --strict',
    '',
    "Note: '--script' is accepted as a repaired typo for '--strict' (a warning "
        'is printed to stderr).',
    '',
    parserUsage,
  ].join('\n');
}

/// The one line the user is shown for a thrown [error].
///
/// The core carries its failures in `Exception`s, whose `toString()` prefixes
/// the type, so the raw rendering reads `Error: Exception: ...`. The prefix is
/// dropped here, at the boundary that owns how a failure is shown. Newlines are
/// flattened so the report stays one line in a terminal.
String userFacingMessage(Object error) {
  final flattened = error
      .toString()
      .replaceAll(RegExp(r'\s*\n\s*'), ' ')
      .trim();
  return flattened.replaceFirst(RegExp(r'^(?:Exception|Error): '), '');
}

String _lastSegment(String path) {
  final parts = path.split(RegExp(r'[/\\]')).where((p) => p.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}

String _trimTrailingSeparators(String path) =>
    path.replaceFirst(RegExp(r'[/\\]+$'), '');

String _trimLeadingSeparators(String path) =>
    path.replaceFirst(RegExp(r'^[/\\]+'), '');

import 'package:promptite/promptite.dart';
import 'package:test/test.dart';

void main() {
  group('invocationLabel', () {
    test('names a compiled binary by its own file name', () {
      // `dart compile exe` makes Platform.script resolve to the executable, so
      // the banner must not tell the user to reach for `dart run`.
      final label = invocationLabel(
        scriptPath: r'C:\repo\build\promptite.exe',
        executablePath: r'C:\repo\build\promptite.exe',
        cwdPath: r'C:\repo',
      );

      expect(label, equals('promptite.exe'));
    });

    test('spells a dart run invocation relative to the current directory', () {
      final label = invocationLabel(
        scriptPath: r'C:\repo\bin\promptite.dart',
        executablePath: r'C:\sdk\dart.exe',
        cwdPath: r'C:\repo',
      );

      expect(label, equals('dart run bin/promptite.dart'));
    });

    test('falls back to the absolute script path from another directory', () {
      final label = invocationLabel(
        scriptPath: r'C:\repo\bin\promptite.dart',
        executablePath: r'C:\sdk\dart.exe',
        cwdPath: r'C:\elsewhere',
      );

      expect(label, equals('dart run C:/repo/bin/promptite.dart'));
    });

    test('tolerates a POSIX layout', () {
      final label = invocationLabel(
        scriptPath: '/home/u/repo/bin/promptite.dart',
        executablePath: '/usr/lib/dart/bin/dart',
        cwdPath: '/home/u/repo/',
      );

      expect(label, equals('dart run bin/promptite.dart'));
    });
  });

  group('renderUsage', () {
    test('names the invocation in the usage line and in both examples', () {
      final usage = renderUsage(
        version: '1.0.0',
        invocation: 'promptite.exe',
        parserUsage: '-t, --task  Main task description (required)',
      );

      expect(usage, contains('promptite version 1.0.0'));
      expect(usage, contains('Usage: promptite.exe <flags>'));
      expect(usage, isNot(contains('dart run')));
      expect(
        usage,
        contains('  promptite.exe -t "Refactor auth" -f "lib/auth.dart'),
      );
      expect(
        usage,
        contains('  promptite.exe -t "Add tests" -c "Focus on login flow"'),
      );
      expect(usage, contains('-t, --task  Main task description (required)'));
      expect(usage, contains('--script'));
    });

    test('ends without a trailing newline for the caller to add', () {
      final usage = renderUsage(
        version: '1.0.0',
        invocation: 'promptite.exe',
        parserUsage: '-h, --help  Show this help and exit',
      );

      expect(usage.endsWith('\n'), isFalse);
    });
  });

  group('userFacingMessage', () {
    test('drops the type prefix an Exception renders itself with', () {
      expect(
        userFacingMessage(Exception('Task is empty')),
        equals('Task is empty'),
      );
    });

    test('leaves an unprefixed message alone', () {
      expect(userFacingMessage('Task is empty'), equals('Task is empty'));
    });

    test('flattens a multi-line message onto one line', () {
      expect(
        userFacingMessage(Exception('first\n  second\n')),
        equals('first second'),
      );
    });
  });
}

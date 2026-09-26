/// End-to-end tests for the CLI itself.
///
/// Every case below runs the **compiled** binary (`dart compile exe`) rather
/// than `dart run`, so the artifact the README tells a Windows user to build is
/// the thing under test: the argument parsing, the `--script` typo repair, the
/// exit codes and the stdout/stderr split. `dart test` alone cannot reach the
/// internals here (`_preprocessArguments` is private and lives in `bin/`), and a
/// stale binary used to report old behaviour; rebuilding in `setUpAll` is what
/// keeps this honest.
///
/// The file-level timeout covers the one-off AOT compile in `setUpAll`, which is
/// slower than the default 30 s on a cold package cache.
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory tmpDir;
  late String exePath;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('promptite_cli_test_');
    exePath = _join(
      tmpDir.path,
      Platform.isWindows ? 'promptite.exe' : 'promptite',
    );
    final root = _packageRoot();
    final compile = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'exe',
      _join('bin', 'promptite.dart'),
      '-o',
      exePath,
    ], workingDirectory: root);
    if (compile.exitCode != 0) {
      fail(
        'dart compile exe failed (exit ${compile.exitCode}):\n'
        '${compile.stdout}\n${compile.stderr}',
      );
    }
  });

  tearDownAll(() {
    try {
      tmpDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows can hold a just-executed binary for a moment longer; a temp
      // directory is cheap, so a failed cleanup is not a test failure.
    }
  });

  ({int exitCode, String out, String err, List<int> outBytes}) runCli(
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    final result = Process.runSync(
      exePath,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: environment == null,
      stdoutEncoding: null,
      stderrEncoding: null,
    );
    final out = result.stdout as List<int>;
    return (
      exitCode: result.exitCode,
      outBytes: out,
      out: utf8.decode(out, allowMalformed: true),
      err: utf8.decode(result.stderr as List<int>, allowMalformed: true),
    );
  }

  group('prompt output', () {
    test(
      'README invocation: task, files, constraints and a token estimate',
      () {
        final r = runCli([
          '-t',
          'Refactor auth',
          '-f',
          'lib/auth.dart,lib/util.dart',
        ]);

        expect(r.exitCode, 0);
        expect(r.out, contains('<task>Refactor auth</task>'));
        expect(
          r.out,
          contains('<files>@lib/auth.dart, @lib/util.dart</files>'),
        );
        expect(r.out, contains('<constraints>'));
        expect(r.out, contains('<instructions>'));
        expect(r.out, contains('Token estimate'));
      },
    );

    test('README invocation: --strict with context', () {
      final r = runCli([
        '-t',
        'Add tests',
        '-c',
        'Focus on login flow',
        '--strict',
      ]);

      expect(r.exitCode, 0);
      expect(r.out, contains('<task>Add tests</task>'));
      expect(r.out, contains('<context>Focus on login flow</context>'));
    });

    test('passes non-ASCII arguments through as UTF-8', () {
      final r = runCli(['-t', 'café naïve']);

      expect(r.exitCode, 0);
      expect(r.outBytes, containsAllInOrder(utf8.encode('<task>café')));
      expect(r.out, contains('<task>café naïve</task>'));
    });

    test('writes LF line endings, never CRLF', () {
      final r = runCli(['-t', 'Refactor auth', '-f', 'lib/auth.dart']);

      // The prompt is a byte stream meant to be piped and pasted, so its line
      // endings must not depend on the platform that produced it.
      expect(r.exitCode, 0);
      expect(r.outBytes.where((b) => b == 0x0a), isNotEmpty);
      expect(r.outBytes.where((b) => b == 0x0d), isEmpty);
    });
  });

  group('usage and exit codes', () {
    test('-h prints usage on stdout and exits 0', () {
      final r = runCli(['-h']);

      expect(r.exitCode, 0);
      expect(r.out, contains('Usage:'));
      expect(r.out, contains('-t, --task'));
      expect(r.err, isEmpty);
    });

    test('no arguments prints usage and exits 0', () {
      final r = runCli([]);

      expect(r.exitCode, 0);
      expect(r.out, contains('Usage:'));
    });

    test('a missing --task exits 1 and reports it on stderr', () {
      final r = runCli(['-f', 'lib/auth.dart']);

      expect(r.exitCode, 1);
      expect(r.err, contains('--task is required'));
      // Which stream the usage banner lands on is the CLI's business; that it
      // is shown at all is the contract.
      expect('${r.out}${r.err}', contains('Usage:'));
    });

    test('an unknown option exits 1', () {
      final r = runCli(['--nope']);

      expect(r.exitCode, 1);
      expect(r.err, contains('--nope'));
    });

    test('file names containing angle brackets exit 1', () {
      final r = runCli(['-t', 't', '-f', 'a<b>.dart']);

      expect(r.exitCode, 1);
      expect(r.err, contains('Invalid characters in file names'));
    });
  });

  group('--script typo repair', () {
    const sixWords = 'one two three four five six';

    test('--script becomes --strict with a warning on stderr', () {
      final r = runCli(['-t', sixWords, '--script']);

      expect(r.exitCode, 0);
      expect(r.err, contains('looks like a typo'));
      expect(r.out, contains('<task>one two three four five</task>'));
      expect(r.out, isNot(contains('six')));
    });

    test('--script=true becomes --strict', () {
      final r = runCli(['-t', sixWords, '--script=true']);

      expect(r.exitCode, 0);
      expect(r.err, contains("Using '--strict' instead"));
      expect(r.out, contains('<task>one two three four five</task>'));
    });

    test('--script:true becomes --strict', () {
      final r = runCli(['-t', sixWords, '--script:true']);

      expect(r.exitCode, 0);
      expect(r.err, contains("Using '--strict' instead"));
      expect(r.out, contains('<task>one two three four five</task>'));
    });

    test('--script=false becomes --no-strict', () {
      final r = runCli(['-t', sixWords, '--script=false']);

      expect(r.exitCode, 0);
      expect(r.err, contains("Using '--no-strict' instead"));
      expect(r.out, contains('<task>$sixWords</task>'));
    });

    test('a non-boolean value is refused instead of guessed', () {
      final r = runCli(['-t', sixWords, '--script=yes']);

      expect(r.exitCode, 1);
      expect(r.err, contains('takes no value'));
      expect(r.out, isEmpty);
    });
  });

  group('compiled artifact', () {
    test('runs from a foreign directory with no Dart SDK on PATH', () {
      // An AOT exe needs no Dart runtime; scrubbing the environment and leaving
      // the package directory proves the artifact is self-contained.
      final r = runCli(
        ['-t', 'standalone'],
        environment: {
          'PATH': Platform.isWindows ? r'C:\Windows\System32' : '/usr/bin',
          if (Platform.isWindows) 'SystemRoot': r'C:\Windows',
        },
      );

      expect(r.exitCode, 0);
      expect(r.out, contains('<task>standalone</task>'));
    });
  });
}

String _join(String a, String b) => '$a${Platform.pathSeparator}$b';

/// The directory `dart test` is running in is the package root, but walk up to
/// the `pubspec.yaml` anyway so a run from a subdirectory still compiles.
String _packageRoot() {
  var dir = Directory.current.absolute;
  while (!File(_join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('no pubspec.yaml above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir.path;
}

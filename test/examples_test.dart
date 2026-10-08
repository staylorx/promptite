// Sets the gate on `example/example.dart`: the runnable example ships as a
// package deliverable, so the `dart test` gate runs it and asserts the output
// it prints, keeping the example from rotting into a file nobody executes.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('examples/example.dart runs and demonstrates the library API', () async {
    final run = await Process.run(Platform.resolvedExecutable, [
      'run',
      'example/example.dart',
    ], workingDirectory: _packageRoot());

    expect(
      run.exitCode,
      0,
      reason: 'stdout:\n${run.stdout}\nstderr:\n${run.stderr}',
    );
    final out = run.stdout as String;
    expect(out, contains('<task>Refactor auth</task>'));
    expect(out, contains('<files>@lib/auth.dart, @lib/session.dart</files>'));
    expect(
      out,
      contains('<context>Keep the public API unchanged; add tests.</context>'),
    );
    expect(out, contains('Token estimate: ~'));
    expect(out, contains('Handled a failure: Task is empty'));
  });
}

String _packageRoot() {
  var dir = Directory.current.absolute;
  while (!File(
    '${dir.path}${Platform.pathSeparator}pubspec.yaml',
  ).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('no pubspec.yaml above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir.path;
}

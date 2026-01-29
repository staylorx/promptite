import 'package:test/test.dart';

// Import the package implementation for testing helper functions.
import 'package:promptite/src/promptite.dart' as cli;

void main() {
  group('generateTightPrompt', () {
    test('includes task, files and context when provided', () {
      final prompt = cli.generateTightPrompt(
        task: 'Refactor auth',
        files: ['lib/auth.dart', 'lib/util.dart'],
        context: 'Focus on login flow',
        strict: false,
      );

      expect(prompt, contains('<task>Refactor auth</task>'));
      expect(prompt, contains('@lib/auth.dart'));
      expect(prompt, contains('<context>Focus on login flow</context>'));
      expect(prompt, contains('<constraints>'));
    });

    test('strict mode truncates task words', () {
      final prompt = cli.generateTightPrompt(
        task: 'one two three four five six seven',
        files: [],
        context: '',
        strict: true,
      );

      expect(prompt, contains('<task>one two three four five</task>'));
      expect(prompt, isNot(contains('six')));
    });
  });

  group('estimateTokens', () {
    test('returns expected heuristic value', () {
      final short = 'abc';
      // (3 / 4).ceil() == 1 + 20 => 21
      expect(cli.estimateTokens(short), equals(21));

      final longer = 'a' * 100;
      // (100 / 4) = 25 + 20 => 45
      expect(cli.estimateTokens(longer), equals(45));
    });
  });
}

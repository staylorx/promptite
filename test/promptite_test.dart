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

  group('failure paths', () {
    test('an empty task is a Left carrying its own message', () {
      final either = cli.taskPrompt('   ', false);

      expect(either.isLeft(), isTrue);
      expect(either.getLeft().toNullable()?.message, equals('Task is empty'));
    });

    test('an empty context is a Left carrying its own message', () {
      final either = cli.contextPrompt('', false);

      expect(either.isLeft(), isTrue);
      expect(
        either.getLeft().toNullable()?.message,
        equals('Context is empty'),
      );
    });

    test('an empty file list is a Left carrying its own message', () {
      final either = cli.filesPrompt(const []);

      expect(either.isLeft(), isTrue);
      expect(
        either.getLeft().toNullable()?.message,
        equals('File list is empty'),
      );
    });

    test('angle brackets in a file name are a Left', () {
      final either = cli.filesPrompt(const ['a<b>.dart']);

      expect(either.isLeft(), isTrue);
      expect(
        either.getLeft().toNullable()?.message,
        equals('Invalid characters in file names'),
      );
    });

    test('the Either composing the prompt propagates the failure', () {
      final either = cli.generateTightPromptEither(
        task: 'Refactor auth',
        files: const ['a<b>.dart'],
      );

      expect(either.isLeft(), isTrue);
      expect(
        either.getLeft().toNullable()?.message,
        equals('Invalid characters in file names'),
      );
    });

    test('the throwing form names the failure once, not twice', () {
      // The CLI prints `error.toString()`, which prefixes `Exception: `; the
      // message itself must not carry a second one.
      expect(
        () => cli.generateTightPrompt(
          task: 'Refactor auth',
          files: const ['a<b>.dart'],
        ),
        throwsA(
          predicate(
            (Object e) =>
                e.toString().contains('Failed to generate prompt: Invalid') &&
                !e.toString().contains('Exception: Invalid'),
          ),
        ),
      );
    });
  });

  group('success paths kept green', () {
    test('a valid file list is a Right carrying the files tag', () {
      final either = cli.filesPrompt(const ['lib/a.dart', 'lib/b.dart']);

      expect(either.isRight(), isTrue);
      expect(
        either.getRight().toNullable(),
        equals('<files>@lib/a.dart, @lib/b.dart</files>'),
      );
    });
  });
}

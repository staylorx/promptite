import 'package:test/test.dart';

import 'package:promptite/promptite.dart';

void main() {
  group('generateTightPrompt', () {
    test('given a task, files and context, when assembling, then all three are '
        'included', () {
      final prompt = generateTightPrompt(
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

    test(
      'given strict mode, when the task has more than five words, then it is '
      'truncated',
      () {
        final prompt = generateTightPrompt(
          task: 'one two three four five six seven',
          files: [],
          context: '',
          strict: true,
        );

        expect(prompt, contains('<task>one two three four five</task>'));
        expect(prompt, isNot(contains('six')));
      },
    );
  });

  group('estimateTokens', () {
    test(
      'given a prompt, then the heuristic returns a deterministic count',
      () {
        final short = 'abc';
        // (3 / 4).ceil() == 1 + 20 => 21
        expect(estimateTokens(short), equals(21));

        final longer = 'a' * 100;
        // (100 / 4) = 25 + 20 => 45
        expect(estimateTokens(longer), equals(45));
      },
    );
  });

  group('failure paths (Left)', () {
    test(
      'given a blank task, then taskPrompt is a Left with its own message',
      () {
        final either = taskPrompt(task: '   ', strict: false);

        expect(either.isLeft(), isTrue);
        expect(either.getLeft().toNullable()?.message, equals('Task is empty'));
      },
    );

    test(
      'given blank context, then contextPrompt is a Left with its own message',
      () {
        final either = contextPrompt(context: '', strict: false);

        expect(either.isLeft(), isTrue);
        expect(
          either.getLeft().toNullable()?.message,
          equals('Context is empty'),
        );
      },
    );

    test(
      'given an empty file list, then filesPrompt is a Left with its own message',
      () {
        final either = filesPrompt(fileList: const []);

        expect(either.isLeft(), isTrue);
        expect(
          either.getLeft().toNullable()?.message,
          equals('File list is empty'),
        );
      },
    );

    test(
      'given an angle bracket in a file name, then filesPrompt is a Left',
      () {
        final either = filesPrompt(fileList: const ['a<b>.dart']);

        expect(either.isLeft(), isTrue);
        expect(
          either.getLeft().toNullable()?.message,
          equals('Invalid characters in file names'),
        );
      },
    );

    test(
      'given a composing failure, then generateTightPromptEither propagates it',
      () {
        final either = generateTightPromptEither(
          task: 'Refactor auth',
          files: const ['a<b>.dart'],
        );

        expect(either.isLeft(), isTrue);
        expect(
          either.getLeft().toNullable()?.message,
          equals('Invalid characters in file names'),
        );
      },
    );

    test('given a composing failure, then the throwing form names it once', () {
      expect(
        () => generateTightPrompt(
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

  group('failure value equality', () {
    test(
      'given the same leaf and message, then failures are equal by value',
      () {
        expect(
          const TaskFailure('Task is empty'),
          equals(const TaskFailure('Task is empty')),
        );
        // A different leaf with the same message is not equal: the runtime type
        // is part of equality.
        expect(
          const ContextFailure('x'),
          isNot(equals(const TaskFailure('x'))),
        );
      },
    );
  });

  group('success paths (Right)', () {
    test(
      'given a valid file list, then filesPrompt is a Right with the files tag',
      () {
        final either = filesPrompt(
          fileList: const ['lib/a.dart', 'lib/b.dart'],
        );

        expect(either.isRight(), isTrue);
        expect(
          either.getRight().toNullable(),
          equals('<files>@lib/a.dart, @lib/b.dart</files>'),
        );
      },
    );
  });
}

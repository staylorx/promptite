part of '../failure.dart';

/// A failure from assembling the `<task>` section of a prompt (e.g. a blank
/// task).
final class TaskFailure extends Failure {
  /// Creates a task failure carrying [message].
  const TaskFailure(super.message);
}

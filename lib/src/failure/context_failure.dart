part of '../failure.dart';

/// A failure from assembling the `<context>` section of a prompt (e.g. a blank
/// context).
final class ContextFailure extends Failure {
  /// Creates a context failure carrying [message].
  const ContextFailure(super.message);
}

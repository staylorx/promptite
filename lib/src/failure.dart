/// The sealed failure hierarchy of this package.
///
/// Every operation that can fail returns a `Left(Failure)` (from
/// `package:fpdart`); consumers switch exhaustively over the `final` leaves in
/// this library (each in its own `part` file). Failures are immutable value
/// objects: equality is by runtime type plus [message], so two
/// `TaskFailure('Task is empty')` values compare equal and can be asserted or
/// matched by value.
library;

part 'failure/task_failure.dart';
part 'failure/context_failure.dart';
part 'failure/files_failure.dart';

/// Base class of every failure this package can produce.
///
/// Sealed so a `switch` over the leaves is exhaustive at compile time. Do not
/// add new leaves casually: [==]/[hashCode] key off the runtime type, so a new
/// leaf changes equality without touching callers.
sealed class Failure {
  /// A one-line, user-facing reason for the failure, or `null` when there is
  /// none.
  const Failure(this.message);

  /// The reason a caller can show or match against.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.runtimeType == runtimeType &&
      other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

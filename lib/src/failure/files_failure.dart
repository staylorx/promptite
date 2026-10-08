part of '../failure.dart';

/// A failure from assembling the `<files>` section of a prompt (e.g. an empty
/// file list, or a file name containing an angle bracket that would corrupt the
/// surrounding XML tags).
final class FilesFailure extends Failure {
  /// Creates a files failure carrying [message].
  const FilesFailure(super.message);
}

/// promptite — assembles a token-lean task/file/context prompt and reports its
/// token cost, as a library (`lib/`) and a CLI (`bin/`).
///
/// **Error style (declared):** the functional core returns fpdart
/// `Either<Failure, String>` — failures are values, in `src/failure.dart`. The
/// one throwing function is [generateTightPrompt], the convenience seam the
/// CLI sits on; nothing else in the library throws.
library;

export 'src/cli_text.dart';
export 'src/failure.dart';
export 'src/promptite.dart';
export 'src/version.dart';

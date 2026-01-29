abstract class Failure {
  final String? message;
  Failure(this.message);
}

class TaskFailure extends Failure {
  TaskFailure(super.message);
}

class ContextFailure extends Failure {
  ContextFailure(super.message);
}

class FilesFailure extends Failure {
  FilesFailure(super.message);
}

class ConfigFailure extends Failure {
  ConfigFailure(super.message);
}

class CliFailure extends Failure {
  CliFailure(super.message);
}

class ApiFailure extends Failure {
  ApiFailure(super.message);
}

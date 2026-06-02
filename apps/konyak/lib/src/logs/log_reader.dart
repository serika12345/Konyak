abstract interface class LogReader {
  Future<LogReadResult> readLog(String path);
}

sealed class LogReadResult {
  const LogReadResult();
}

final class ReadLog extends LogReadResult {
  const ReadLog({required this.content});

  final String content;
}

final class LogReadFailure extends LogReadResult {
  const LogReadFailure({required this.message});

  final String message;
}

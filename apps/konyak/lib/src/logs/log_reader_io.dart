import 'dart:io';

import 'log_reader.dart';

final class DartIoLogReader implements LogReader {
  const DartIoLogReader();

  @override
  Future<LogReadResult> readLog(String path) async {
    try {
      final content = await File(path).readAsString();

      return ReadLog(content: content);
    } on FileSystemException catch (error) {
      return LogReadFailure(message: error.message);
    }
  }
}

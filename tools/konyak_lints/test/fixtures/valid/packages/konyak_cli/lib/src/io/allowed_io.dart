import 'dart:convert';
import 'dart:io';

String readBoundaryFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return '';
  }

  return file.readAsStringSync();
}

String readBoundaryEnvironment() {
  return Platform.environment['HOME'] ?? '';
}

class DartIoAllowedBoundary {
  const DartIoAllowedBoundary();

  void write(StringSink output) {
    output.writeln(jsonEncode(<String, Object?>{'ok': true}));
  }
}
